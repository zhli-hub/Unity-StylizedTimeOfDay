using UnityEngine;
[ExecuteAlways]
public class LightMatrixToSkybox : MonoBehaviour
{
    public Light mainLight;
    private static readonly int MainLightViewMat = Shader.PropertyToID("_MainLightViewMat");

    void Start()
    {
        
    }

    void Update()
    {
        Matrix4x4 mainLightViewMat = mainLight.transform.localToWorldMatrix;
        Shader.SetGlobalMatrix(MainLightViewMat, mainLightViewMat);
    }
}