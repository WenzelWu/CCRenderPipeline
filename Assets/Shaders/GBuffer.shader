Shader "CCRP/GBuffer"
{
    Properties
    {
        _MainTex ("Albedo", 2D) = "white" {}
        [Space(25)]
        _Metallic_Global ("Metallic", Range(0,1)) = 0
        _Roughness_Global ("Roughness", Range(0,1)) = 0.5
        [Space(25)]
        [Toggle]_Use_Metal_Map ("Use Metallic Map", Float) = 0
        _MetallicRoughnessMap ("Metallic (R) Roughness (A)", 2D) = "white" {}
        [Space(25)]
        _EmissionMap ("Emission", 2D) = "white" {}
        [Space(25)]
        _OcculsionMap ("Occulsion", 2D) = "white" {}
        [Space(25)]
        [Toggle]_Use_Normal_Map ("Use Normal Map", Float) = 0
        [Normal]_NormalMap ("Normal Map", 2D) = "bump" {}
    }
    
    SubShader
    {
        Tags { "LightMode"="GBuffer" }
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 5.0
            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            void frag (
                v2f i,
                out float4 GT0 : SV_Target0,
                out float4 GT1 : SV_Target1,
                out float4 GT2 : SV_Target2,
                out float4 GT3 : SV_Target3)
            {
                float3 color = tex2D(_MainTex, i.uv).rgb;
                float3 normal = normalize(i.normal);

                GT0 = float4(color, 1);
                GT1 = float4(normal*0.5+0.5, 0);
                GT2 = float4(1,1,0,1);
                GT3 = float4(0,0,1,1);
            }

            ENDCG
        }
    }
}