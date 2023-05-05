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
        _MetallicGlossMap ("Metallic (R) Gloss (A)", 2D) = "white" {}
        [Space(25)]
        _EmissionMap ("Emission", 2D) = "white" {}
        [Space(25)]
        _OcculsionMap ("Occulsion", 2D) = "white" {}
        [Space(25)]
        [Toggle]_Use_Normal_Map ("Use Normal Map", Float) = 0
        [Normal]_BumpMap ("Normal Map", 2D) = "bump" {}
        _BumpScale ("Normal Scale", Range(0,1)) = 1
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
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                float4 t2w0 : TEXCOORD1;
                float4 t2w1 : TEXCOORD2;
                float4 t2w2 : TEXCOORD3;
            };

            sampler2D _MainTex;
            sampler2D _MetallicGlossMap;
            sampler2D _EmissionMap;
            sampler2D _OcculsionMap;
            sampler2D _BumpMap;
            float4 _MainTex_ST;
            float _Metallic_Global;
            float _Roughness_Global;
            float _Use_Metal_Map;
            float _Use_Normal_Map;
            float _BumpScale;

            v2f vert(appdata v)
            {
                v2f o;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.vertex = mul(UNITY_MATRIX_VP, float4(worldPos, 1.0));
                
                if(_Use_Normal_Map)
                {
                    float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                    float3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
                    float3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

                    o.t2w0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                    o.t2w1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                    o.t2w2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);
                }
                else
                {
                    o.t2w0 = float4(1,0,0,worldPos.x);
                    o.t2w1 = float4(0,1,0,worldPos.y);
                    o.t2w2 = float4(0,0,1,worldPos.z);
                }
                
                o.normal = v.normal;
                return o;
            }

            void frag (
                v2f i,
                out float4 GT0 : SV_Target0,
                out float4 GT1 : SV_Target1,
                out float4 GT2 : SV_Target2,
                out float4 GT3 : SV_Target3)
            {
                float4 color = tex2D(_MainTex, i.uv);
                float3 emission = tex2D(_EmissionMap, i.uv).rgb;
                float3 normal = normalize(i.normal);
                float metallic = _Metallic_Global;
                float roughness = _Roughness_Global;
                float ao = tex2D(_OcculsionMap, i.uv).r;

                if(_Use_Metal_Map)
                {
                    float4 metal = tex2D(_MetallicGlossMap, i.uv);
                    metallic = metal.r;
                    roughness = 1.0 - metal.a;
                }

                if(_Use_Normal_Map)
                {
                    normal = UnpackNormal(tex2D(_BumpMap, i.uv));
                    normal.xy *= _BumpScale;
                    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                    const float3x3 t2w = float3x3(i.t2w0.xyz, i.t2w1.xyz, i.t2w2.xyz);
                    normal = normalize(mul(t2w, i.normal));
                }

                GT0 = color;
                GT1 = float4(normal*0.5+0.5, 0);
                GT2 = float4(0,0,roughness,metallic);
                GT3 = float4(emission,ao);
            }

            ENDCG
        }
    }
}