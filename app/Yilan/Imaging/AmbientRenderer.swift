import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation

/// 环境光背景：把当前图片的小图做大半径模糊、提高饱和度、压暗到 50%（对应设计稿 .amb）
enum AmbientRenderer {
    private static let context = CIContext(options: [.cacheIntermediates: false])

    /// 输入缩略图，输出已经模糊好的小图；界面上直接拉伸铺满，不需要实时模糊
    static func render(_ source: CGImage) -> CGImage? {
        // 先缩到 96 像素宽，再模糊，开销很小
        let input = CIImage(cgImage: source)
        let scale = 96 / max(input.extent.width, 1)
        let small = input.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let extent = small.extent

        // 设计稿：窗口约 1740pt 宽时模糊 80pt；对应 96px 宽的小图约 4.5px
        let blur = CIFilter.gaussianBlur()
        blur.inputImage = small.clampedToExtent()
        blur.radius = 4.5

        let color = CIFilter.colorControls()
        color.inputImage = blur.outputImage
        color.saturation = 1.7

        // brightness(.5)：RGB 整体乘 0.5
        let dim = CIFilter.colorMatrix()
        dim.inputImage = color.outputImage
        dim.rVector = CIVector(x: 0.5, y: 0, z: 0, w: 0)
        dim.gVector = CIVector(x: 0, y: 0.5, z: 0, w: 0)
        dim.bVector = CIVector(x: 0, y: 0, z: 0.5, w: 0)

        guard let output = dim.outputImage?.cropped(to: extent) else { return nil }
        return context.createCGImage(output, from: extent)
    }
}
