using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanarReflectionManager : MonoBehaviour
{
    private Camera _reflectionCamera;
    private Camera _mainCamera;

    private RenderTexture _renderTarget;

    public GameObject reflectionPlane;

    Material _reflectionPlaneMat;

    void Start()
    {
        GameObject reflectionCameraGo = new GameObject("ReflectionCamera");
        _reflectionCamera = reflectionCameraGo.AddComponent<Camera>();

        _mainCamera = Camera.main;

        _renderTarget = new RenderTexture(Screen.width, Screen.height, 24);

        _reflectionPlaneMat = reflectionPlane.GetComponent<MeshRenderer>().sharedMaterial;
        _reflectionPlaneMat.SetTexture("_ReflectionTex", _renderTarget);
    }

    void Update()
    {

    }

    void OnPreRender()
    {
        RenderReflection();
    }

    private void RenderReflection()
    {
        _reflectionCamera.CopyFrom(_mainCamera);

        Vector3 cameraDirectionWorldSpace = _mainCamera.transform.forward;
        Vector3 cameraUpWorldSpace = _mainCamera.transform.up;
        Vector3 cameraPositionWorldSpace = _mainCamera.transform.position;

        //Transform the vector to the floor's space
        Vector3 cameraDirectionPlaneSpace = reflectionPlane.transform.InverseTransformDirection(cameraDirectionWorldSpace);
        Vector3 cameraUpPlaneSpace = reflectionPlane.transform.InverseTransformDirection(cameraUpWorldSpace);
        Vector3 cameraPositionPlaneSpace = reflectionPlane.transform.InverseTransformPoint(cameraPositionWorldSpace);

        // Mirror the vectors
        cameraDirectionPlaneSpace.y *= -1.0f;
        cameraUpPlaneSpace.y *= -1.0f;
        cameraPositionPlaneSpace.y *= -1.0f;

        // Transform the vectors back to world space
        cameraDirectionWorldSpace = reflectionPlane.transform.TransformDirection(cameraDirectionPlaneSpace);
        cameraUpWorldSpace = reflectionPlane.transform.TransformDirection(cameraUpPlaneSpace);
        cameraPositionWorldSpace = reflectionPlane.transform.TransformPoint(cameraPositionPlaneSpace);

        // Set camere position and rotation
        _reflectionCamera.transform.position = cameraPositionWorldSpace;
        _reflectionCamera.transform.LookAt(cameraPositionWorldSpace + cameraDirectionWorldSpace, cameraUpWorldSpace);

        // Set render target for the reflection camera
        _reflectionCamera.targetTexture = _renderTarget;

        // Render the reflection camera
        _reflectionCamera.Render();
    }
}
