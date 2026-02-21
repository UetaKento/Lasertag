using Anaglyph.XRTemplate;
using UnityEngine;

namespace Anaglyph.Lasertag
{
	public class RayPlaceSphere : MonoBehaviour
	{
		[SerializeField] private Transform controllerTransform;
		[SerializeField] private GameObject sphereMarker;
		[SerializeField] private float maxDistance = 10f;
		[SerializeField] private LineRenderer lineRenderer;

		private bool isBusy = false;

		private void Awake()
		{
			if (lineRenderer == null)
				lineRenderer = gameObject.AddComponent<LineRenderer>();

			lineRenderer.positionCount = 2;
			lineRenderer.startWidth = 0.005f;
			lineRenderer.endWidth = 0.005f;
			lineRenderer.useWorldSpace = true;
		}

		private async void LateUpdate()
		{
			if (isBusy) return;
			if (EnvironmentMapper.Instance == null) return;
			if (controllerTransform == null) return;

			isBusy = true;

			Vector3 origin = controllerTransform.position;
			Vector3 direction = controllerTransform.forward;

			Ray ray = new(origin, direction);
			var result = await EnvironmentMapper.Instance.RaymarchAsync(ray, maxDistance);

			if (!enabled)
			{
				isBusy = false;
				return;
			}

			Vector3 endPoint = result.didHit
				? result.point
				: origin + direction * maxDistance;

			// レイの描画
			lineRenderer.SetPosition(0, origin);
			lineRenderer.SetPosition(1, endPoint);

			// マーカー球の移動
			if (sphereMarker != null)
			{
				sphereMarker.SetActive(result.didHit);
				if (result.didHit)
					sphereMarker.transform.position = result.point;
			}

			isBusy = false;
		}

		private void OnDisable()
		{
			if (sphereMarker != null)
				sphereMarker.SetActive(false);

			lineRenderer.SetPosition(0, Vector3.zero);
			lineRenderer.SetPosition(1, Vector3.zero);
		}
	}
}
