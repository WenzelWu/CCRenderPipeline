using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

public class CCRenderPipeline : RenderPipeline
{
    
    //gt0: ARGB32-Albedo R8G8B8A8
    //gt1: ARGB2101010-Normal R10G10B10
    //gt2: ARGB64-MotionVector R16G16, Roughness B16, Metallic A16
    //gt3: ARGBFloat-Emission R16G16B16A16, Occlusion A16
    
    //TODO: 1.优化GBuffer的格式 2.LWGUI 3.PBR算法
    //gt0: ARGBFloat-WoldPos, R32G32B32
    //gt1: ARGB2101010-Normal, R10G10B10
    //gt2: ARGB2101010-Albedo, R10G10B10
    //gt3: RGB565-Roughness, R5, Occlusion G6, Metallic B5 Occ会不会太小了
    //gt4: RG16-MotionVector, R16G16
    //gt5: RGB111110Float-Emission, R11G11B10

    RenderTexture _gDepth; // TODO: DepthStencil
    RenderTexture[]  _gBuffers = new RenderTexture[4];
    RenderTargetIdentifier[] _gBufferId = new RenderTargetIdentifier[4];
    
    public CCRenderPipeline()
    {
        _gDepth  = new RenderTexture(Screen.width, Screen.height, 24, RenderTextureFormat.Depth, RenderTextureReadWrite.Linear);
        _gBuffers[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
        _gBuffers[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear);
        _gBuffers[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB64, RenderTextureReadWrite.Linear);
        _gBuffers[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGBFloat, RenderTextureReadWrite.Linear);

        // _gBuffer[0] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear);
        // _gBuffer[1] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.ARGB2101010, RenderTextureReadWrite.Linear);
        // _gBuffer[2] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RGB565, RenderTextureReadWrite.Linear);
        // _gBuffer[3] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RG16, RenderTextureReadWrite.Linear);
        // _gBuffer[4] = new RenderTexture(Screen.width, Screen.height, 0, RenderTextureFormat.RGB111110Float, RenderTextureReadWrite.Linear);
        
        for(int i=0; i<4; i++) _gBufferId[i] = _gBuffers[i];
    }
    
    protected override void Render(ScriptableRenderContext context, Camera[] cameras)
    {
        Camera camera = cameras[0];
        context.SetupCameraProperties(camera);
        
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "GBuffer";
        
        //bind gBuffer
        cmd.SetRenderTarget(_gBufferId, _gDepth);
        cmd.SetGlobalTexture("_gDepth", _gDepth);
        for (int i = 0; i < 4; i++) cmd.SetGlobalTexture("_GT" + i, _gBuffers[i]);
        
        //clear
        cmd.ClearRenderTarget(true, true, Color.black);
        context.ExecuteCommandBuffer(cmd);

        //cull
        camera.TryGetCullingParameters(out var cullingParameters);
        var cullResults = context.Cull(ref cullingParameters);
        
        //config settings
        ShaderTagId shaderTagId = new ShaderTagId("GBuffer"); // use shader which lightmode is gbuffer
        SortingSettings sortingSettings = new SortingSettings(camera);
        DrawingSettings drawingSettings = new DrawingSettings(shaderTagId, sortingSettings);
        FilteringSettings filteringSettings = FilteringSettings.defaultValue;
        
        //draw
        context.DrawRenderers(cullResults, ref drawingSettings, ref filteringSettings);

        //skybox and gizmos
        context.DrawSkybox(camera);
        if (Handles.ShouldRenderGizmos())
        {
            context.DrawGizmos(camera, GizmoSubset.PreImageEffects);
            context.DrawGizmos(camera, GizmoSubset.PostImageEffects);
        }
        
        //light pass
        LightPass(context, camera);

        //submit
        context.Submit();
    }

    private void LightPass(ScriptableRenderContext context, Camera camera)
    {
        CommandBuffer cmd = new CommandBuffer();
        cmd.name = "LightPass";
        
        Material mat = new Material(Shader.Find("CCRP/LightPass"));
        cmd.Blit(_gBufferId[0], BuiltinRenderTextureType.CameraTarget, mat);
        context.ExecuteCommandBuffer(cmd);
    }
}
