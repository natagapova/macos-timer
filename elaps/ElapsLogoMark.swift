import SwiftUI

struct ElapsLogoMark: View {
    let appearance: AppAppearance

    var body: some View {
        Image(appearance.usesLightLogo ? "LogoMarkLight" : "LogoMarkDark")
            .resizable()
            .renderingMode(.original)
            .interpolation(.high)
            .scaledToFit()
    }
}
