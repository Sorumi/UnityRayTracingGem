

float _IOR;
int _TraceCount;
float3 _Color;
float _AbsorbIntensity;
float _ColorAdd;
float _ColorMultiply;
samplerCUBE _Cubemap;

float _Specular;

static const float PI = 3.14159265f;
static const float EPSILON = 1e-8;

//-------------------------------------
//- MESH

struct MeshObject
{
    float4x4 localToWorldMatrix;
    int indicesOffset;
    int indicesCount;
};

int _MeshIndex;

StructuredBuffer<MeshObject> _MeshObjects;
StructuredBuffer<float3> _Vertices;
StructuredBuffer<int> _Indices;

struct v2f
{
    float4 pos: SV_POSITION;
    float4 uv: TEXCOORD0;
    float4 screenPos: TEXCOORD1;
};


//-------------------------------------
//- RAY

struct Ray
{
    float3 origin;
    float3 direction;
    float3 energy;
    float absorbDistance;
};

Ray CreateRay(float3 origin, float3 direction)
{
    Ray ray;
    ray.origin = origin;
    ray.direction = direction;
    ray.energy = float3(1.0f, 1.0f, 1.0f);
    ray.absorbDistance = 0;
    return ray;
}

Ray CreateCameraRay(float2 uv)
{
    // Transform the camera origin to world space
    float3 origin = mul(UNITY_MATRIX_I_V, float4(0.0f, 0.0f, 0.0f, 1.0f)).xyz;
    
    // Invert the perspective _CameraInverseProjection of the view-space position
    float3 direction = mul(unity_CameraInvProjection, float4(uv, 0.0f, 1.0f)).xyz;
    // Transform the direction from camera to world space and normalize
    direction = mul(UNITY_MATRIX_I_V, float4(direction, 0.0f)).xyz;
    direction = normalize(direction);
    
    return CreateRay(origin, direction);
}

//-------------------------------------
//- RAYHIT

struct RayHit
{
    float3 position;
    float distance;
    float3 normal;
};

RayHit CreateRayHit()
{
    RayHit hit;
    hit.position = float3(0.0f, 0.0f, 0.0f);
    hit.distance = 1.#INF;
    hit.normal = float3(0.0f, 0.0f, 0.0f);
    return hit;
}


bool IntersectTriangle_MT97_NoCull(Ray ray, float3 vert0, float3 vert1, float3 vert2,
inout float t, inout float u, inout float v)
{
    // find vectors for two edges sharing vert0
    float3 edge1 = vert1 - vert0;
    float3 edge2 = vert2 - vert0;
    
    // begin calculating determinant - also used to calculate U parameter
    float3 pvec = cross(ray.direction, edge2);
    
    // if determinant is near zero, ray lies in plane of triangle
    float det = dot(edge1, pvec);
    
    // use no culling
    if (det > - EPSILON && det < EPSILON)
        return false;
    float inv_det = 1.0f / det;
    
    // calculate distance from vert0 to ray origin
    float3 tvec = ray.origin - vert0;
    
    // calculate U parameter and test bounds
    u = dot(tvec, pvec) * inv_det;
    if (u < 0.0 || u > 1.0f)
        return false;
    
    // prepare to test V parameter
    float3 qvec = cross(tvec, edge1);
    
    // calculate V parameter and test bounds
    v = dot(ray.direction, qvec) * inv_det;
    if (v < 0.0 || u + v > 1.0f)
        return false;
    
    // calculate t, ray intersects triangle
    t = dot(edge2, qvec) * inv_det;
    
    return true;
}

void IntersectMeshObject(Ray ray, inout RayHit bestHit, MeshObject meshObject)
{
    uint offset = meshObject.indicesOffset;
    uint count = offset +meshObject.indicesCount;
    
    for (uint i = offset; i < count; i += 3)
    {
        float3 v0 = (mul(meshObject.localToWorldMatrix, float4(_Vertices[_Indices[i]], 1))).xyz;
        float3 v1 = (mul(meshObject.localToWorldMatrix, float4(_Vertices[_Indices[i + 1]], 1))).xyz;
        float3 v2 = (mul(meshObject.localToWorldMatrix, float4(_Vertices[_Indices[i + 2]], 1))).xyz;
        
        float t, u, v;
        if (IntersectTriangle_MT97_NoCull(ray, v0, v1, v2, t, u, v))
        {
            if(t > 0 && t < bestHit.distance)
            {
                bestHit.distance = t;
                bestHit.position = ray.origin + t * ray.direction;
                bestHit.normal = normalize(cross(v1 - v0, v2 - v0));
            }
        }
    }
}

//-------------------------------------
//- TRACE

RayHit Trace(Ray ray)
{
    RayHit bestHit = CreateRayHit();
    
    // Trace mesh objects
    IntersectMeshObject(ray, bestHit, _MeshObjects[_MeshIndex]);
    
    return bestHit;
}

//-------------------------------------
//- SHADE

float3 SampleCubemap(float3 direction)
{
    return texCUBElod(_Cubemap, float4(direction, 0)).xyz;
}

float Refract(float3 i, float3 n, float eta, inout float3 o)
{
    float cosi = dot(-i, n);
    float cost2 = 1.0f - eta * eta * (1 - cosi * cosi);
    
    o = eta * i + ((eta * cosi - sqrt(cost2)) * n);
    return 1 - step(cost2, 0);
}

float FresnelSchlick(float3 normal, float3 incident, float ref_idx)
{
    float cosine = dot(-incident, normal);
    float r0 = (1 - ref_idx) / (1 + ref_idx); // ref_idx = n2/n1
    r0 = r0 * r0;
    float ret = r0 + (1 - r0) * pow((1 - cosine), 5);
    return ret;
}

float3 Shade(inout Ray ray, RayHit hit, int depth)
{
    
    if (hit.distance < 1.#INF && depth < (_TraceCount - 1))
    {
        float3 specular = float3(0, 0, 0);
        
        float eta;
        float3 normal;
        
        // out
        if (dot(ray.direction, hit.normal) > 0)
        {
            normal = -hit.normal;
            eta = _IOR;
        }
        // in
        else
        {
            normal = hit.normal;
            eta = 1.0 / _IOR;
        }
        
        ray.origin = hit.position - normal * 0.001f;
        
        float3 refractRay;
        float refracted = Refract(ray.direction, normal, eta, refractRay);
        
        if (depth == 0.0)
        {
            float3 reflectDir = reflect(ray.direction, hit.normal);
            reflectDir = normalize(reflectDir);
            
            float3 reflectProb = FresnelSchlick(normal, ray.direction, eta) * _Specular;
            specular = SampleCubemap(reflectDir) * reflectProb;
            ray.energy *= 1 - reflectProb;
        }
        else
        {
            ray.absorbDistance += hit.distance;
        }
        
        // Refraction
        if (refracted == 1.0)
        {
            ray.direction = refractRay;
        }
        // Total Internal Reflection
        else
        {
            ray.direction = reflect(ray.direction, normal);
        }
        
        ray.direction = normalize(ray.direction);
        
        return specular;
    }
    else
    {
        ray.energy = 0.0f;

        float3 cubeColor = SampleCubemap(ray.direction);
        float3 absorbColor = float3(1.0, 1.0, 1.0) - _Color;
        float3 absorb = exp(-absorbColor * ray.absorbDistance * _AbsorbIntensity);

        return cubeColor * absorb * _ColorMultiply + _ColorAdd * _Color;
    }
}

