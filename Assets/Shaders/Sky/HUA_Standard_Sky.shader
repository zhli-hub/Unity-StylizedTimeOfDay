Shader "HUA/HUA_Standard_Sky"
{
    Properties
    {
        [Header(Gradient Sky)]
        [Space]
        _DayBottomColor("白天底部颜色", color) = (0,0,0,1)
        _DayTopColor("白天顶部颜色", color) = (0.7,0.7,1,1)
        _NightBottomColor("夜晚底部颜色", color) = (0,0,0,1)
        _NightTopColor("夜晚顶部颜色", color) = (0.7,0.7,1,1)
        _SkyGradientExponent("天空衰减指数", Range(0, 20)) = 10
        
        [Header(Sun Moon Disk)]
        [Space]
        _SunRadius("太阳圆盘大小", Range(0, 15)) = 1
        _SunInnerBoundary("太阳内边界", Range(0, 10)) = 1
        _SunOuterBoundary("太阳外边界", Range(0, 10)) = 1
        
        _MoonRadius("月亮圆盘大小", Range(0, 15)) = 1
        _MoonInnerBoundary("月亮内边界", Range(0, 10)) = 1
        _MoonOuterBoundary("月亮外边界", Range(0, 10)) = 1
        [NoScaleOffset]_MoonTex("月亮贴图", 2D) = "white"{}
        
        [Header(Halo Effect)]
        [Space]
        _SunHaloColor("太阳光环颜色", color) = (1,1,1,1)
        _SunHaloExponent("太阳光环指数", float) = 125
        _SunHaloContribution("太阳光环贡献度", Range(0, 1)) = 0.75
        _MoonHaloColor("月亮光环颜色", color) = (0.6,0.7,1,1)
        _MoonHaloExponent("月亮光环指数", float) = 125
        _MoonHaloContribution("月亮光环贡献度", Range(0, 1)) = 0.1
        
        [Header(Starry)]
        [Space]
        _StarSpeed("星星闪烁速度", Range(0.01, 1)) = 0.03
        _StarCutoff("星星密度", Range(0.01, 1)) = 0.08
        [NoScaleOffset]_StarNoiseTex("星星噪声贴图", 2D) = "black"{}
        [NoScaleOffset]_StarColorLut("星星颜色图", 2D) = "white"{}
        
        [Header(Horizon)]
        [Space]
        _HorizonLineDayColor("早上天际线颜色", color) = (1, 0.7, 0,1)
        _HorizonLineNightColor("晚上天际线颜色", color) = (0.1,0.3,0.6,1)
        _HorizonLineContribution("天际线贡献度", Range(0, 1)) = 0.5
        _HorizonLineExponent("天际线指数", Range(0, 20)) = 10
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
