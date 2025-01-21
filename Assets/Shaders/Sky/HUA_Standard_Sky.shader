Shader "HUA/HUA_Standard_Sky"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _SunRadius("太阳圆盘大小", Range(0, 15)) = 1
        _SunInnerBoundary("太阳内边界", Range(0, 10)) = 1
        _SunOuterBoundary("太阳外边界", Range(0, 10)) = 1
        
        _MoonRadius("月亮圆盘大小", Range(0, 15)) = 1
        _MoonInnerBoundary("月亮内边界", Range(0, 10)) = 1
        _MoonOuterBoundary("月亮外边界", Range(0, 10)) = 1
        _MoonTex("月亮贴图", 2D) = "white"{}
        
        _DayBottomColor("白天底部颜色", color) = (0,0,0,1)
        _DayTopColor("白天顶部颜色", color) = (0.7,0.7,1,1)
        
        _NightBottomColor("夜晚底部颜色", color) = (0,0,0,1)
        _NightTopColor("夜晚顶部颜色", color) = (0.7,0.7,1,1)
        _SkyGradientExponent("天空衰减指数", Range(0, 20)) = 10
        
        _HorizonLineDuskColor("傍晚天际线颜色", color) = (1, 0.7, 0,1)
        _HorizonLineNoonColor("中午天际线颜色", color) = (1,1,1,1)
        _HorizonLineContribution("天际线贡献度", Range(0, 1)) = 0.5
        _HorizonLineExponent("天际线指数", Range(0, 20)) = 10
        
        _SunHaloColor("太阳光环颜色", color) = (1,1,1,1)
        _SunHaloExponent("太阳光环指数", float) = 125
        _SunHaloContribution("太阳光环贡献度", Range(0, 1)) = 0.75
        _MoonHaloColor("月亮光环颜色", color) = (0.6,0.7,1,1)
        _MoonHaloExponent("月亮光环指数", float) = 125
        _MoonHaloContribution("月亮光环贡献度", Range(0, 1)) = 0.1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma enable_d3d11_debug_symbols
            
            #include "Assets/Shaders/HLSL/Sky/SkyCommon.hlsl"
            
            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(v.vertex);
                o.vertex = vertexInput.positionCS;
                o.uv = v.uv;
                o.positionWS = vertexInput.positionWS;
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                float3 viewDir = normalize(i.positionWS);
                half3 gradientSky = GetGradientSkyAndDisk(viewDir, _MainLightPosition);
                
                half4 col = half4(gradientSky, 1.0);
                return col;
            }
            ENDHLSL
        }
    }
}
