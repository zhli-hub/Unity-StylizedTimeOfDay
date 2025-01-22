#pragma once

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

// 需要满足SUN_MOON_DISK_TILLING * SUN_MOON_DISK_BASE_SIZE = 100
#define MOON_DISK_TILLING 10
#define MOON_DISK_BASE_SIZE 10

CBUFFER_START(UnityPerMaterial)
half _SunRadius;
half _SunInnerBoundary;
half _SunOuterBoundary;

half _MoonRadius;
half _MoonInnerBoundary;
half _MoonOuterBoundary;
sampler2D _MoonTex;
float4x4 _MainLightViewMat;

half3 _DayBottomColor;
half3 _DayMidColor;
half3 _DayTopColor;

half3 _NightBottomColor;
half3 _NightMidColor;
half3 _NightTopColor;

half _SkyGradientExponent;

half3 _HorizonLineDayColor;
half3 _HorizonLineNightColor;
half _HorizonLineContribution;
half _HorizonLineExponent;

half3 _SunHaloColor;
half _SunHaloExponent;
half3 _MoonHaloColor;
half _MoonHaloExponent;
half _SunHaloContribution;
half _MoonHaloContribution;

half _StarSpeed;
half _StarCutoff;
sampler2D _StarNoiseTex;
sampler2D _StarColorLut;
CBUFFER_END

struct appdata
{
    float4 vertex : POSITION;
    float4 uv : TEXCOORD0;
};

struct v2f
{
    float4 uv : TEXCOORD0;
    float4 vertex : SV_POSITION;
    float3 positionWS : TEXCOORD1;
};

float4 hash4(float2 p)
{
    return frac(sin(float4(1.0 + dot(p, float2(37.0, 17.0)),
                           2.0 + dot(p, float2(11.0, 47.0)),
                           3.0 + dot(p, float2(41.0, 29.0)),
                           4.0 + dot(p, float2(23.0, 31.0)))) * 103.0);
}

half3 GetSunMoonDisk(float3 viewDir, float3 sunDir, half sunHaloMask, half moonHaloMask)
{
    // Sun
    float sunDist = distance(viewDir, sunDir.xyz);
    float sunArea = 1 - (sunDist / (_SunRadius * 0.01) );
    sunArea = smoothstep(_SunOuterBoundary * 0.1, _SunInnerBoundary * 0.1, sunArea) * sunHaloMask;

    // Moon
    float moonDist = distance(viewDir, -sunDir.xyz);
    float moonArea = 1 - (moonDist / (_MoonRadius * 0.01));
    moonArea = smoothstep(_MoonOuterBoundary * 0.1, _MoonInnerBoundary * 0.1, moonArea) * moonHaloMask;
    float scale = _MoonRadius / MOON_DISK_BASE_SIZE;
    float offset = lerp(0.5, 0, scale);
    float3 moonUV = mul(viewDir, _MainLightViewMat);
    moonUV.xy = moonUV.xy * MOON_DISK_TILLING;
    moonUV.xy = moonUV.xy * 0.5 + 0.5;
    moonUV.xy = (moonUV - offset) / scale;
    half3 moonColor = tex2D(_MoonTex, moonUV.xy).rgb;

    return sunArea * _MainLightColor.rgb + moonArea * moonColor;
}

void ComputeSkyMasks(float3 viewDir, float3 sunDir, float3 moonDir, out half sunHalo, out half moonHalo, out half horizon, out half gradient)
{
    sunHalo = 0;
    moonHalo = 0;
    horizon = 0;
    gradient = 0;

    half dotViewUp = dot(viewDir, half3(0, 1, 0));
    half dotViewSun = dot(viewDir, sunDir);
    half dotViewMoon = dot(viewDir, moonDir);

    float bellCurve = pow(saturate(dotViewSun), _SunHaloExponent * saturate(abs(dotViewUp)));
    float horizonSoften = 1 - pow(1 - saturate(dotViewUp), 50);
    sunHalo = saturate(bellCurve * horizonSoften);

    bellCurve = pow(saturate(dotViewMoon), _MoonHaloExponent * saturate(abs(dotViewUp)));
    moonHalo = saturate(bellCurve * horizonSoften);

    horizon = saturate(1 - abs(viewDir.y));
    horizon = pow(horizon, _HorizonLineExponent);
    horizon *= saturate(smoothstep(-0.4, 0, sunDir.y) * smoothstep(-0.4, 0, -sunDir.y) * 1);

    gradient = 1 - saturate(viewDir.y);
    gradient = pow(gradient, _SkyGradientExponent);
}

half3 GetStarry(float3 viewDir, float3 sunDir)
{
    half2 starUV = viewDir.xz / viewDir.y;
    half2 iuv = floor(starUV);
    float4 ofa = hash4(iuv + half2(0.2, 0.6));
    starUV = ofa + frac(starUV);
                
    half stars = tex2D(_StarNoiseTex, (starUV + _StarSpeed * _Time.x)).r;
    stars *= saturate(-sunDir.y) * step(0, viewDir.y);
    stars = step(1 - _StarCutoff, stars);
    
    half3 starColor = tex2D(_StarColorLut, float2(starUV.x, 0)) * stars * 2;
    return starColor;
}

half3 GetGradientSkyAndDisk(float3 viewDir, float3 sunDir)
{
    half maskSunDisc, maskSunHalo, maskMoonHalo, maskHorizon, maskGradient;
    ComputeSkyMasks(viewDir, sunDir, -sunDir, maskSunHalo, maskMoonHalo, maskHorizon, maskGradient);

    half3 sunMoonDisk = GetSunMoonDisk(viewDir, sunDir, maskSunHalo, maskMoonHalo);

    float sunNightStep = smoothstep(-0.33, 0.25, sunDir.y);

    half3 gradientDay = lerp(_DayTopColor, _DayBottomColor, maskGradient);
    half3 gradientNight = lerp(_NightTopColor, _NightBottomColor, maskGradient);
    
    half3 gradientSky = lerp(gradientNight, gradientDay, sunNightStep);

    half3 horizonColor = lerp(_HorizonLineNightColor, _HorizonLineDayColor, sunNightStep);
    gradientSky = lerp(gradientSky, horizonColor * 2, pow(_HorizonLineContribution * maskHorizon, 0.3));

    half3 finalSunHaloColor = lerp(_SunHaloColor, horizonColor, _HorizonLineContribution * maskHorizon);

    half3 starry = GetStarry(viewDir, sunDir);
    gradientSky += finalSunHaloColor * _SunHaloContribution * maskSunHalo + _MoonHaloColor * _MoonHaloContribution * maskMoonHalo;
    gradientSky += starry;
// DEBUG
    // gradientSky = maskHorizon.rrr;
    // gradientSky = maskGradient.rrr;
    // gradientSky = maskMoonHalo.rrr;
    // gradientSky = maskHorizon.rrr * horizonColor;
    // gradientSky = (pow(_HorizonLineContribution * maskHorizon, 0.5)).rrr;
// DEBUG
    
    return gradientSky + sunMoonDisk;
}