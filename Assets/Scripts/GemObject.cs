using UnityEngine;

[RequireComponent(typeof(MeshRenderer))]
[RequireComponent(typeof(MeshFilter))]
public class GemObject : MonoBehaviour
{
    private void OnEnable()
    {
        GemManager.RegisterObject(this);
    }
    
    private void OnDisable()
    {
        GemManager.UnregisterObject(this);
    }
}
