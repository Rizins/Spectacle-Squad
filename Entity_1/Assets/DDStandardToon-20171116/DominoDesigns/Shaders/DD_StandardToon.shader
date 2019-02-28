// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)
// Modifed to use David Leon's toon BRDF by Domino Marama

Shader "Domino Designs/Standard Toon"
{
    Properties
    {
        [Enum(OFF,0,FRONT,1,BACK,2)] _CullMode("Cull Mode", int) = 2
        _Color("Color", Color) = (1,1,1,1)
        _MainTex("Albedo", 2D) = "white" {}

        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        _Glossiness("Smoothness", Range(0.0, 1.0)) = 0.5
        _GlossMapScale("Smoothness Scale", Range(0.0, 1.0)) = 1.0
        [Enum(Metallic Alpha,0,Albedo Alpha,1)] _SmoothnessTextureChannel ("Smoothness texture channel", Float) = 0

        [Gamma] _Metallic("Metallic", Range(0.0, 1.0)) = 0.0
        _MetallicGlossMap("Metallic", 2D) = "white" {}

        [ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1.0
        [ToggleOff] _GlossyReflections("Glossy Reflections", Float) = 1.0

        _BumpScale("Scale", Float) = 1.0
        _BumpMap("Normal Map", 2D) = "bump" {}

        _Parallax ("Height Scale", Range (0.005, 0.08)) = 0.02
        _ParallaxMap ("Height Map", 2D) = "black" {}

        _OcclusionStrength("Strength", Range(0.0, 1.0)) = 1.0
        _OcclusionMap("Occlusion", 2D) = "white" {}

        _EmissionColor("Color", Color) = (0,0,0)
        _EmissionMap("Emission", 2D) = "white" {}

        _DetailMask("Detail Mask", 2D) = "white" {}

        _DetailAlbedoMap("Detail Albedo x2", 2D) = "grey" {}
        _DetailNormalMapScale("Scale", Float) = 1.0
        _DetailNormalMap("Normal Map", 2D) = "bump" {}

        [Enum(UV0,0,UV1,1)] _UVSec ("UV Set for secondary textures", Float) = 0

        [Toggle] _UseToonData ("Use Toon Data", Float) = 0.0
        _EdgeBlack ("", Range(0.0, 1.0)) = 0.45
        _EdgeWhite ("", Range(0.0, 1.0)) = 0.55
        _ClampBlack ("", Range(0.0, 2.0)) = 0.1
        _ClampWhite ("", Range(0.0, 2.0)) = 0.9
        [Toggle] _SpecularEdge ("Specular Highlights", Float) = 1.0
        _LightWarp ("", 2D) = "" {}

        [Toggle] _OutlineEnabled ( "Outline", Float ) = 1.0
        _OutlineColor ( "Outline Color", Color ) = ( 0.0, 0.0, 0.0, 1.0 )
        _Outline ( "Outline Width", Range ( 0.0, 0.1 ) ) = 0.004
        _OutlineFade ("Outline Fade Threshold", Range (0.0, 1.0)) = 1.0
        _OutlineColorMix("Base Color Mix", Range (0.0, 1.0)) = 0.0

        // Blending state
        [HideInInspector] _Mode ("__mode", Float) = 0.0
        [HideInInspector] _SrcBlend ("__src", Float) = 1.0
        [HideInInspector] _DstBlend ("__dst", Float) = 0.0
        [HideInInspector] _ZWrite ("__zw", Float) = 1.0
    }

    CGINCLUDE
        #define UNITY_SETUP_BRDF_INPUT MetallicSetup
    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 300


        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull[_CullMode]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
            #pragma shader_feature _PARALLAXMAP
            #pragma shader_feature _SPECULAR_EDGE
            #pragma shader_feature _DD_USE_LIGHT_WARP

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "../CGIncludes/ToonBRDF.cginc"
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual
            Cull[_CullMode]

            CGPROGRAM
            #pragma target 3.0

            // -------------------------------------


            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature ___ _DETAIL_MULX2
            #pragma shader_feature _PARALLAXMAP
            #pragma shader_feature _SPECULAR_EDGE
            #pragma shader_feature _DD_USE_LIGHT_WARP

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog
            // Uncomment the following line to enable dithering LOD crossfade. Note: there are more in the file to uncomment for other passes.
            //#pragma multi_compile _ LOD_FADE_CROSSFADE

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "../CGIncludes/ToonBRDF.cginc"
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        // Outline Pass

        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "Always" }

            Cull Front
            Zwrite On ZTest Less

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #include "UnityCG.cginc"
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #pragma shader_feature _ _ALPHABLEND_ON _ALPHATEST_ON
            #pragma shader_feature _ _DD_USE_TOON_DATA

            float _OutlineEnabled;
            float _Outline;
            float4 _OutlineColor;
            float _OutlineColorMix;
            float _OutlineFade;
            float _Mode;
            float4 _Color;
#if defined(_ALPHATEST_ON)
            float _Cutoff;
#endif
            sampler2D _MainTex;
            float4 _MainTex_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
#if defined(_DD_USE_TOON_DATA)
                float4 color : COLOR;
#endif
            };

            struct v2f
            {
                float4 pos : POSITION;
                float3 normal : NORMAL;
                UNITY_FOG_COORDS( 2 )
                float4 color : COLOR;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                o.pos = UnityObjectToClipPos ( v.vertex );
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
#if defined(_DD_USE_TOON_DATA)
                float3 norm = v.color.rgb;
                norm = mul( ( float3x3 )UNITY_MATRIX_IT_MV, norm);
#else
                float3 norm = mul( ( float3x3 )UNITY_MATRIX_IT_MV, v.normal );
#endif
                float2 offset = TransformViewToProjection( norm.xy );
                float viewDistance = -(UnityObjectToViewPos( v.vertex ).z);
                viewDistance = _ProjectionParams.z * _OutlineFade / viewDistance;

#if defined(_DD_USE_TOON_DATA)
                o.pos.xy += (min(_Outline, _Outline * viewDistance) * v.color.a) * offset;
#else
                o.pos.xy += min(_Outline, _Outline * viewDistance) * offset;
#endif
#if defined(UNITY_REVERSED_Z)
                o.pos.z -= 0.00015;
#else
                o.pos.z += 0.00015;
#endif
                o.uv = TRANSFORM_TEX( v.uv, _MainTex );
                o.color.rgb = _OutlineColor.rgb;
                o.color.a = saturate(_OutlineColor.a * viewDistance);
#ifdef _ALPHABLEND_ON
                o.color.a *= _Color.a;
#endif
                return o;
            }

            half4 frag( v2f i ) :COLOR
            {
                half4 texColor = tex2D( _MainTex, i.uv );
#if defined(_ALPHATEST_ON)
                clip((_Color.a * texColor.a) - _Cutoff);
#endif
                i.color.rgb = lerp(i.color.rgb, _Color.rgb * texColor.rgb, _OutlineColorMix);
                UNITY_APPLY_FOG( i.fogCoord, i.color );
                return i.color;
            }
            ENDCG
        }
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "PerformanceChecks"="False" }
        LOD 150

        // ------------------------------------------------------------------
        //  Base forward pass (directional light, emission, lightmaps, ...)
        Pass
        {
            Name "FORWARD"
            Tags { "LightMode" = "ForwardBase" }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            Cull[_CullMode]

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _EMISSION
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature _ _GLOSSYREFLECTIONS_OFF
            // SM2.0: NOT SUPPORTED shader_feature ___ _DETAIL_MULX2
            // SM2.0: NOT SUPPORTED shader_feature _PARALLAXMAP

            #pragma skip_variants SHADOWS_SOFT DIRLIGHTMAP_COMBINED

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog

            #pragma vertex vertBase
            #pragma fragment fragBase
            #include "../CGIncludes/ToonBRDF.cginc"
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
        // ------------------------------------------------------------------
        //  Additive forward pass (one light per pass)
        Pass
        {
            Name "FORWARD_DELTA"
            Tags { "LightMode" = "ForwardAdd" }
            Blend [_SrcBlend] One
            Fog { Color (0,0,0,0) } // in additive pass fog should be black
            ZWrite Off
            ZTest LEqual
            Cull[_CullMode]

            CGPROGRAM
            #pragma target 2.0

            #pragma shader_feature _NORMALMAP
            #pragma shader_feature _ _ALPHATEST_ON _ALPHABLEND_ON _ALPHAPREMULTIPLY_ON
            #pragma shader_feature _METALLICGLOSSMAP
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            #pragma shader_feature _ _SPECULARHIGHLIGHTS_OFF
            #pragma shader_feature ___ _DETAIL_MULX2
            // SM2.0: NOT SUPPORTED shader_feature _PARALLAXMAP
            #pragma skip_variants SHADOWS_SOFT

            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile_fog

            #pragma vertex vertAdd
            #pragma fragment fragAdd
            #include "../CGIncludes/ToonBRDF.cginc"
            #include "UnityStandardCoreForward.cginc"

            ENDCG
        }
    }

    FallBack "Standard"
    CustomEditor "DD_StandardToonShaderGUI"
}
