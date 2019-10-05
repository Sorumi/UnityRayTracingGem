Shader "Custom/GemShader"
{
    Properties
    {
        _Cubemap ("Skybox", Cube) = "_Skybox" { }

        _TraceCount ("Trace Count", Int) = 5
        _IOR ("IOR", Range(1, 5)) = 2.417

        _Color ("Color", Color) = (1, 1, 1, 1)
        _AbsorbIntensity ("Absorb Intensity", Range(0, 10)) = 1.0
        _ColorMultiply ("Color Multiply", Range(0, 5)) = 1.0
        _ColorAdd ("Color Add", Range(0, 1)) = 0.0

        _Specular ("Specular", Range(0, 1)) = 0.0

    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        
        
        Pass
        {
            CGPROGRAM
            
            #include "UnityCG.cginc"
            #include "RayTracing.cginc"
            
            #pragma target 5.0
            #pragma vertex vert
            #pragma fragment frag
            
            
            //Vertex Shader
            v2f vert(appdata_base v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.pos);
                o.uv = float4(v.texcoord.xy, v.texcoord.z, 1);
                return o;
            }
            
            //Fragment Shader
            half4 frag(v2f i): COLOR
            {
                float2 screenUV = i.screenPos.xy / i.screenPos.w;
                screenUV = screenUV * 2.0f - 1.0f;
                
                Ray ray = CreateCameraRay(screenUV);

                float3 result = float3(0, 0, 0);

                [unroll(10)]
                for (int i = 0; i < _TraceCount; i ++)
                {
                    RayHit hit = Trace(ray);
                    result += ray.energy * Shade(ray, hit, i);
                    
                    if (!any(ray.energy))
                        break;
                }
                return half4(result, 1);
            }
            
            ENDCG
            
        }
    }
    FallBack "Diffuse"
}
