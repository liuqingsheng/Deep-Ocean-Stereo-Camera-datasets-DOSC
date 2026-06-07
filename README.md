## Description
Deep-sea optical imaging is predominantly performed under artificial illumination, where wavelength-dependent absorption causes severe spectral imbalance and rapid attenuation of long-wavelength components. Unlike shallow-water scenes illuminated mainly by natural light, deep-sea images are acquired under localized artificial lighting, and their radiometric appearance is strongly coupled with the light source–scene–camera geometry. As a result, color degradation varies with propagation distance and cannot be adequately described by models that assume spatially uniform ambient illumination, stable background light, or scene-independent attenuation. This limits the applicability of conventional underwater enhancement and restoration methods developed primarily for shallow-water or naturally illuminated conditions. This paper proposes a physically motivated and computationally lightweight color restoration framework for real-time deep-sea stereo imaging. The proposed method exploits stereo-derived depth to guide wavelength-dependent attenuation compensation and restores the attenuated red channel using a depth-guided red–green correction model under an absorption-dominated imaging assumption. To enhance robustness under varying scene depths and illumination conditions, a global intensity constraint is introduced to adaptively regulate the compensation strength, while a saturation-aware compression module suppresses over-amplification in high-luminance regions. Owing to its predominantly pixel-wise formulation, the algorithm is naturally amenable to parallel execution, has linear computational complexity, and requires approximately 120 arithmetic operations per pixel, making it suitable for embedded deep-sea imaging platforms. The proposed method is evaluated on fourteen representative stereo image pairs covering natural benthic environments and artificial subsea structures, and compared with representative underwater enhancement and restoration methods, including MLLE, WWPF, FUnIE-GAN, SS-UIE, Five A+, and RAUNE-Net. In a coral color-validation case, the proposed method reduces the CIEDE2000 color difference (ΔE00) from approximately 43 to 14, corresponding to an improvement of more than 66%. End-to-end deployment on an NVIDIA Jetson TX2 achieves approximately 15 FPS at 1080p and 50 FPS at 720p. These results demonstrate that incorporating stereo-derived depth into attenuation compensation provides a practical, interpretable, and real-time solution for color restoration in deep-sea optical imaging.

## License

The DGRC algorithm code is released for non-commercial research and educational use only. Commercial use, including but not limited to commercial products, paid services, commercial datasets, and industrial deployment, is not permitted without prior written permission from the copyright holders.

The DOSC dataset, including images, depth maps, and calibration files, is released for non-commercial research and educational use only. Users must provide proper attribution when using this dataset in publications, presentations, or derivative research.

All rights not expressly granted are reserved.

## Citation

If you use the DGRC algorithm code or the DOSC dataset in your research, please cite the following paper:

```bibtex
@article{liu2026depth,
  title   = {Depth-guided attenuation compensation for real-time color restoration in deep-sea stereo imaging},
  author  = {Liu, Qingsheng and Miao, Jianjun and Zhang, Xilin and Wang, Hebo and Sun, Zhilei and Wang, Zihao and Li, Xuecheng and Li, Chao},
  journal = {ISPRS Journal of Photogrammetry and Remote Sensing},
  volume  = {238},
  pages   = {736--755},
  year    = {2026},
  issn    = {0924-2716},
  doi     = {10.1016/j.isprsjprs.2026.05.037}
}
```

