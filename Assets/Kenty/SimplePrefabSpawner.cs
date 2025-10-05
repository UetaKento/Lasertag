using UnityEngine;

public class SimplePrefabSpawner : MonoBehaviour
{
    public GameObject Prefab;
    public GameObject PreviewPrefab;
    private GameObject _currentPreview;

    private void Start()
    {
        _currentPreview = Instantiate(PreviewPrefab);
    }

    private void Update()
    {
        var ray = new Ray(OVRInput.GetLocalControllerPosition(OVRInput.Controller.RTouch),
                            OVRInput.GetLocalControllerRotation(OVRInput.Controller.RTouch) * Vector3.forward);
        // var ray = new Ray(BulletPrefab.transform.position, BulletPrefab.transform.rotation * Vector3.forward);
        if (Physics.Raycast(ray, out RaycastHit hit))
        {
            Debug.Log("Hit " + hit.point);
            _currentPreview.transform.position = hit.point;
            _currentPreview.transform.rotation = Quaternion.FromToRotation(Vector3.up, hit.normal);
            if (OVRInput.GetDown(OVRInput.Button.One))
            {
                Instantiate(Prefab, hit.point, Quaternion.FromToRotation(Vector3.up, hit.normal));
                Debug.Log("Spawned prefab!!");
            }
        }else
        {
            Debug.Log("No Hit");
        }
    }
}
