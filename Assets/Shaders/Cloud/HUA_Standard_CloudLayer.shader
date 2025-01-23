Shader "HUA/HUA_Standard_CloudLayer"
{
    Properties
    {
        _UseQuadMesh ("Use Quad Mesh ?", Range(0, 1)) = 0
        [NoScaleOffset]_FrontMap ("Front Map", 2D) = "white" { }
        [NoScaleOffset]_BackMap ("Front Map", 2D) = "white" { }
        _YRotation ("Texture Rotation", Range(0, 360)) = 180
        _Density ("Absorption", Range(1, 20)) = 1
        
        _CloudSDF ("Cloud Size", Range(0, 1)) = 1
        _CloudSDFSmooth ("Cloud SDF Smooth", Range(0, 1)) = 0.3

        _WindOrientation ("Wind Orientation", Range(0, 360)) = 0
        _WindSpeed ("Wind Speed", Float) = 10
    }

    HLSLINCLUDE
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    ENDHLSL

    SubShader
    {
        Tags { "RenderPipeline" = "UniversalPipeline" "Queue"="Transparent" "IgnoreProjector"="True"}

        Pass
        {

            Tags { "LightMode" = "UniversalForward" "RenderType" = "Transparent" }
            Blend SrcAlpha OneMinusSrcAlpha
            // Blend One One

            HLSLPROGRAM

            #pragma target 4.0
            #pragma vertex VERT
            #pragma fragment FRAG

            #define BLEND_FOG_BLANCED
            #define NO_POISON_CIRCLE

            #pragma enable_d3d11_debug_symbols
            
            #include "Assets/Shaders/HLSL/Cloud/CloudLayer.hlsl"

            v2f VERT(a2v i)
            {
                v2f o;
                o.positionCS = TransformObjectToHClip(i.position.xyz);
                o.positionWS      = TransformObjectToWorld(i.position.xyz);
                o.texcoord   = i.texCoord.xy;
                o.normalWS   = TransformObjectToWorldNormal(i.normalOS);
                float3 dirCameraToPos = _WorldSpaceCameraPos - o.positionWS.xyz;
                dirCameraToPos = normalize(dirCameraToPos);
                
                o.fogCoord = half4(0.1, 0.1, 0.2, 0.5);
                return o;
            }
            
            real4 FRAG(v2f i): SV_TARGET
            {
                Light mainLight = GetMainLight();

                float3 LightDir = normalize(mainLight.direction);
                float3 ViewDir = normalize(_WorldSpaceCameraPos.xyz - i.positionWS.xyz);
                
                LightDir = RotateAroundYInDegrees(LightDir, _YRotation);

                float HGPhase = PhaseHG(0.8, dot(LightDir, ViewDir)) * 0 + 1;

                float4 RigRTBk; 
                float4 RigLBtF;
                
                RigRTBk = SAMPLE_TEXTURE2D(_FrontMap, sampler_linear_repeat, i.texcoord).rgba;
                RigLBtF = SAMPLE_TEXTURE2D(_BackMap, sampler_linear_repeat, i.texcoord).rgba;

                float timeCoff = sin(_Time.y) * 0.5 + 0.5;
                float sdf = smoothstep(saturate(timeCoff - _CloudSDFSmooth), timeCoff + _CloudSDFSmooth, RigLBtF.a);
                
                float d = atan(-i.normalWS.z / abs(i.normalWS.x)) * 180.0f / 3.14f - 90.f;
                LightDir = RotateAroundYInDegrees(LightDir, d * (i.normalWS.x < 0 ? -1 : 1));
                
                float3 Weights                  = LightDir > 0 ? RigRTBk.xyz : RigLBtF.xyz;
                float3 SqrDir                   = LightDir * LightDir;
                float  Transmission             = dot(SqrDir, Weights);

                float Opacity = pow(RigLBtF.y, 2.2);
                // Opacity = ViewDir.y < 0 ? Opacity : 0;
                Opacity = saturate(Opacity * 0.0005 * i.positionWS.y);

                float3 DirectDiffuse      = exp(-1.0f * (1 - Transmission) * _Density) * _MainLightColor.rgb;
                float3 RimEnhance         = min(1, pow(Transmission, 6)) * HGPhase * _MainLightColor.rgb * 1;

                DirectDiffuse     += RimEnhance;
                half4 color = half4(DirectDiffuse, Opacity * 1);
                color.rgb = i.fogCoord.rgb + color.rgb * (1 - i.fogCoord.a);
                // color = ApplyVertexFogCommon(color, i.positionCS, i.positionWS.xyz, i.fogCoord, 0);
                return color;
            }

            ENDHLSL
        }
    }
}