Shader "Lasertag/DepthVisualize"
{
	Properties
	{
		_FloorColor ("Floor Color", Color) = (0.2, 0.5, 1.0, 1)
		_WallColor ("Wall Color", Color) = (0.2, 1.0, 0.4, 1)
		_CeilingColor ("Ceiling Color", Color) = (1.0, 0.6, 0.2, 1)
		_Alpha ("Alpha", Range(0, 1)) = 0.6
		_MaxDist ("Max Distance", Float) = 6.0
	}

	SubShader
	{
		Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
		ZWrite Off
		ZTest LEqual
		Cull Front
		Blend SrcAlpha OneMinusSrcAlpha

		Pass
		{
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "Assets/Anaglyph/XRTemplate/Depth/DepthKit.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

			CBUFFER_START(UnityPerMaterial)
				half3 _FloorColor;
				half3 _WallColor;
				half3 _CeilingColor;
				half _Alpha;
				float _MaxDist;
			CBUFFER_END

			struct Attributes
			{
				float4 positionOS : POSITION;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct Varyings
			{
				float4 positionHCS : SV_POSITION;
				float3 positionWS : TEXCOORD0;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			Varyings vert(Attributes IN)
			{
				Varyings OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.positionHCS = TransformObjectToHClip(IN.positionOS);
				OUT.positionWS = TransformObjectToWorld(IN.positionOS);
				return OUT;
			}

			half4 frag(Varyings IN) : SV_Target
			{
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);
				const int eye = unity_StereoEyeIndex;

				// このフラグメントのワールド座標を深度カメラのNDC空間に変換
				const float3 ndc = agDepthWorldToNDC(IN.positionWS, eye);

				// 深度カメラの視野外はスキップ
				if (any(abs(ndc.xy) > 1.0))
					discard;

				// 深度テクスチャから実際のサーフェス深度を取得
				const float depthNDC = agDepthSample(ndc.xy, eye, bilinearClampSampler);

				// 有効な深度データがなければスキップ
				if (depthNDC <= 0.0)
					discard;

				// サーフェスの法線と世界座標を取得
				float3 surfaceNorm = agDepthNormalSample(ndc.xy, eye, bilinearClampSampler);
				float3 surfaceWorld = agDepthNDCtoWorld(float3(ndc.xy, depthNDC), eye);

				// 距離による減衰（遠くほど透明）
				float3 eyePos = agDepthEyePos(eye);
				float dist = length(surfaceWorld - eyePos);
				float fade = 1.0 - saturate(dist / _MaxDist);

				// 法線のY成分で床・壁・天井を色分け
				// upDot +1 = 床（上向き法線）, -1 = 天井（下向き法線）, 0 = 壁
				float upDot = dot(surfaceNorm, float3(0, 1, 0));
				float floorW  = saturate((upDot - 0.3) / 0.4);
				float ceilW   = saturate((-upDot - 0.3) / 0.4);
				float wallW   = 1.0 - floorW - ceilW;

				half3 color = _FloorColor * floorW + _WallColor * wallW + _CeilingColor * ceilW;

				return half4(color, _Alpha * fade);
			}

			ENDHLSL
		}
	}
}
