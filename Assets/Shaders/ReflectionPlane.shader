Shader "Custom/ReflectionPlane"
{
    Properties
    {
        _Color ("Color", Color) = (1, 1, 1, 1)
        _MainTex ("Albedo (RGB)", 2D) = "white" { }
        _Glossiness ("Smoothness", Range(0, 1)) = 0.5
        _Metallic ("Metallic", Range(0, 1)) = 0.0

        _Reflection("Reflection", Range(0, 1)) = 0.5
        _Specular("Specular", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 200
        
        CGPROGRAM
        
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows
        
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0
        
        sampler2D _MainTex;
        
        struct Input
        {
            float2 uv_MainTex;
            float4 screenPos;
        };
        
        half _Glossiness;
        half _Metallic;
        half _Reflection;
        half _Specular;
        fixed4 _Color;
        
        sampler2D _ReflectionTex;
        
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
        
        void surf(Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            float2 screenUV = IN.screenPos.xy / IN.screenPos.w;
            screenUV.x = 1.0f - screenUV.x;
            float3 reflection = tex2D(_ReflectionTex, screenUV);
            
            o.Albedo = lerp(c.rgb, c.rgb + reflection * _Reflection, _Specular);
            
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
        
    }
    FallBack "Diffuse"
}
