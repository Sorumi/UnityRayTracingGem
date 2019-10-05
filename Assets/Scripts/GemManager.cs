using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

public class GemManager : MonoBehaviour
{

    struct MeshObject
    {
        public Matrix4x4 localToWorldMatrix;
        public int indicesOffset;
        public int indicesCount;

    }
    private static List<GemObject> _gemObjects = new List<GemObject>();
    private static List<MeshObject> _meshObjects = new List<MeshObject>();
    private static List<Vector3> _vertices = new List<Vector3>();
    private static List<int> _indices = new List<int>();
    private ComputeBuffer _meshObjectBuffer;
    private ComputeBuffer _vertexBuffer;
    private ComputeBuffer _indexBuffer;

    private static List<Transform> _transformsToWatch = new List<Transform>();
    private static bool _meshObjectsNeedRebuilding = true;

    void Start()
    {

    }

    void Update()
    {

        if (Input.GetKeyDown(KeyCode.F12))
        {
            ScreenCapture.CaptureScreenshot("Screenshot/" + Time.time + ".png");
        }

        foreach (Transform t in _transformsToWatch)
        {
            if (t.hasChanged)
            {
                _meshObjectsNeedRebuilding = true;
                t.hasChanged = false;
            }
        }

        if (_meshObjectsNeedRebuilding)
        {
            BuildMeshObjectBuffers();
            SetMaterialParameters();
            _meshObjectsNeedRebuilding = false;
        }
    }

    void OnDisable()
    {
        _meshObjectBuffer?.Release();
        _vertexBuffer?.Release();
        _indexBuffer?.Release();
    }


    public static void RegisterObject(GemObject obj)
    {
        _gemObjects.Add(obj);
        _transformsToWatch.Add(obj.transform);
        _meshObjectsNeedRebuilding = true;
    }
    public static void UnregisterObject(GemObject obj)
    {
        _gemObjects.Remove(obj);
        _transformsToWatch.Remove(obj.transform);
        _meshObjectsNeedRebuilding = true;
    }


    private void BuildMeshObjectBuffers()
    {
        // Clear all lists
        _meshObjects.Clear();
        _vertices.Clear();
        _indices.Clear();

        foreach (GemObject obj in _gemObjects)
        {
            MeshFilter filter = obj.GetComponent<MeshFilter>();
            Mesh mesh = filter.sharedMesh;

            // Add vertex data
            int firstVertex = _vertices.Count;
            _vertices.AddRange(mesh.vertices);

            // Add index data - if the vertex buffer wasn't empty before, the
            // indices need to be offset
            int firstIndex = _indices.Count;
            var indices = mesh.GetIndices(0);
            _indices.AddRange(indices.Select(index => index + firstVertex));

            // Add the object itself
            _meshObjects.Add(new MeshObject()
            {
                localToWorldMatrix = obj.transform.localToWorldMatrix,
                indicesOffset = firstIndex,
                indicesCount = indices.Length
            });
        }

        CreateComputeBuffer(ref _meshObjectBuffer, _meshObjects, 72);
        CreateComputeBuffer(ref _vertexBuffer, _vertices, 12);
        CreateComputeBuffer(ref _indexBuffer, _indices, 4);
    }



    private static void CreateComputeBuffer<T>(ref ComputeBuffer buffer, List<T> data, int stride)
        where T : struct
    {
        // Do we already have a compute buffer?
        if (buffer != null)
        {
            // If no data or buffer doesn't match the given criteria, release it
            if (data.Count == 0 || buffer.count != data.Count || buffer.stride != stride)
            {
                buffer.Release();
                buffer = null;
            }
        }

        if (data.Count != 0)
        {
            // If the buffer has been released or wasn't there to
            // begin with, create it
            if (buffer == null)
            {
                buffer = new ComputeBuffer(data.Count, stride);
            }

            // Set data on the buffer
            buffer.SetData(data);
        }
    }

    private void SetMaterialParameters()
    {
        for (int i = 0; i < _gemObjects.Count; i++)
        {
            GemObject obj = _gemObjects[i];

            MeshRenderer renderer = obj.GetComponent<MeshRenderer>();
            Material material = renderer.sharedMaterial;

            material.SetBuffer("_MeshObjects", _meshObjectBuffer);
            material.SetBuffer("_Vertices", _vertexBuffer);
            material.SetBuffer("_Indices", _indexBuffer);

            MaterialPropertyBlock block = new MaterialPropertyBlock();
            renderer.GetPropertyBlock(block);
            block.SetInt("_MeshIndex", i);
            renderer.SetPropertyBlock(block);
        }
    }

}