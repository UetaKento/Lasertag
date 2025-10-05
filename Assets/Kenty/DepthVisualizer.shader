Shader "Custom/DepthVisualizer"
{
    Properties
    {
        [KeywordEnum(Depth, Normal, Edge)] _VisMode("Visualization Mode", Float) = 0
        _Eye("Eye Index", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _VISMODE_DEPTH _VISMODE_NORMAL _VISMODE_EDGE
            
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            // DepthKitDriverが設定するグローバル変数
            Texture2DArray<float> agDepthTex;
            Texture2DArray<float4> agDepthNormalTex;
            Texture2DArray<float4> agDepthEdgeTex;
            SamplerState sampler_agDepthTex;
            
            float _Eye;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                uint eye = (uint)_Eye;
                
                #ifdef _VISMODE_DEPTH
                    // 深度を視覚化（0=近い、1=遠い）
                    float depth = agDepthTex.Sample(sampler_agDepthTex, float3(i.uv, eye));
                    return fixed4(depth, depth, depth, 1);
                    
                #elif _VISMODE_NORMAL
                    // 法線を視覚化（-1~1を0~1にマッピング）
                    float3 normal = agDepthNormalTex.Sample(sampler_agDepthTex, float3(i.uv, eye)).xyz;
                    return fixed4(normal * 0.5 + 0.5, 1);
                    
                #elif _VISMODE_EDGE
                    // エッジ検出結果を視覚化
                    float4 edge = agDepthEdgeTex.Sample(sampler_agDepthTex, float3(i.uv, eye));
                    return edge;
                    
                #endif
                
                return fixed4(0, 0, 1, 1); // フォールバック（マゼンタ）
            }
            ENDCG
        }
    }
}
