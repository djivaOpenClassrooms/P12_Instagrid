import SwiftUI

struct MainView: View {
    @EnvironmentObject var layoutViewModel: LayoutViewModel
    @EnvironmentObject var imagePickerViewModel: ImagePickerViewModel

    @Environment(\.verticalSizeClass) var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass: UserInterfaceSizeClass?

    @State var verticalOffset: CGFloat = CGFloat.zero
    @State var horizontalOffset: CGFloat = CGFloat.zero

    @State var rect: CGRect = .zero
    @State var gridImage: UIImage? = nil
    @State var activeSheet: ActiveSheet?
    @State var isGridLayoutEmpty: Bool = false

    var body: some View {
        let headerView = HeaderView()
        let gridLayout = GridLayout(activeSheet: $activeSheet, rect: $rect)
            .offset(x: horizontalOffset, y: verticalOffset)
        let layoutButtons = LayoutButtons()
        
        ZStack {
            Color.yellow
                .edgesIgnoringSafeArea(.all)
            if isPortraitMode() {
                GeometryReader { geometry in
                    VStack {
                        headerView
                        gridLayout
                        HStack {
                            layoutButtons
                        }
                        .padding(.bottom)
                        .padding(.horizontal)
                        
                        
                    }.frame(width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .center)
                }
            } else {
                GeometryReader { geometry in
                    HStack {
                        headerView
                        VStack {
                            Text("Instagrid")
                                .font(Font.custom("ThirstySoftRegular", size: 30))
                                .padding(.top, 8)
                            gridLayout
                        }
                        
                        VStack {
                            Spacer()
                            layoutButtons
                            Spacer()
                        }
                    }
                    .frame(width: geometry.size.width,
                           height: geometry.size.height,
                           alignment: .center)
                }
            }
        }
        .sheet(item: $activeSheet) { item in
            switch item {
            case .pickImage:
                ImagePicker(
                    sourceType: imagePickerViewModel.sourceType,
                    completionHandler: { image in
                        imagePickerViewModel.didSelectImage(image)
                        self.activeSheet = nil
                    }
                )
            case .share:
                ShareView(activityItems: [self.gridImage as Any], callback: {_,_,_,_ in
                    withAnimation {
                        self.verticalOffset = 0
                        self.horizontalOffset = 0
                    }
                })
            }
        }
        .alert(isPresented: $isGridLayoutEmpty) {
            Alert(title: Text("No images"), message: Text("Please select some images before sharing."), dismissButton: .default(Text("OK"), action: {
                withAnimation {
                    self.verticalOffset = 0
                    self.horizontalOffset = 0
                }
            }))
        }
        .gesture(DragGesture(minimumDistance: 3, coordinateSpace: .global)
                    .onEnded({ (value) in
                        gridImage = UIApplication.shared.windows[0].rootViewController?.view.asImage(rect: self.rect)
                        // up swipe
                        if value.translation.height < 0 && isPortraitMode() {
                            withAnimation {
                                self.verticalOffset = -UIScreen.main.bounds.size.height
                            }
                        }
                        // left swipe
                        else if value.translation.width < 0 && !isPortraitMode() {
                            withAnimation {
                                self.horizontalOffset = -UIScreen.main.bounds.size.width
                            }
                        }
                        
                        if isShowingAtLeastOneImage() {
                            activeSheet = .share
                        } else {
                            isGridLayoutEmpty = true
                        }
                    })
        )
    }
    
    private func isPortraitMode() -> Bool {
        return horizontalSizeClass == .compact && verticalSizeClass == .regular
    }
    
    
}

// Extension for checking presence of image in the gridLayout
extension MainView {
    private var isFirstLayoutButtonSelected: Bool {
        return layoutViewModel.showBottomRightRectangle && !layoutViewModel.showTopLeftRectangle
    }
    
    private var isContainingImageForFirstLayoutButton: Bool {
        return imagePickerViewModel.selectedImageTopRight != nil
            || imagePickerViewModel.selectedImageBottomRight != nil
            || imagePickerViewModel.selectedImageBottomLeft != nil
    }
    
    private var isSecondLayoutButtonSelected: Bool {
        return !layoutViewModel.showBottomRightRectangle && layoutViewModel.showTopLeftRectangle
    }
    
    private var isContainingImageForSecondLayoutButton: Bool {
        return imagePickerViewModel.selectedImageTopRight != nil
            || imagePickerViewModel.selectedImageTopLeft != nil
            || imagePickerViewModel.selectedImageBottomLeft != nil
    }
    
    private var isThirdLayoutButtonSelected: Bool {
        return layoutViewModel.showBottomRightRectangle && layoutViewModel.showTopLeftRectangle
    }
    
    private var isContainingImageForThirdLayoutButton: Bool {
        return imagePickerViewModel.selectedImageTopRight != nil
            || imagePickerViewModel.selectedImageTopLeft != nil
            || imagePickerViewModel.selectedImageBottomRight != nil
            || imagePickerViewModel.selectedImageBottomLeft != nil
    }
    
    private func isShowingAtLeastOneImage() -> Bool {
        var isShowing: Bool = false
        // Check presence of image for the first LayoutButton configuration
        if isFirstLayoutButtonSelected {
            if isContainingImageForFirstLayoutButton {
                isShowing = true
            }
        }
        // Check presence of image for the second LayoutButton configuration
        else if isSecondLayoutButtonSelected {
            if isContainingImageForSecondLayoutButton {
                isShowing = true
            }
        }
        // Check presence of image for the third LayoutButton configuration
        else if isThirdLayoutButtonSelected {
            if isContainingImageForThirdLayoutButton {
                isShowing = true
            }
        }
        return isShowing
    }
}

enum ActiveSheet: Identifiable {
    case share, pickImage
    
    var id: Int {
        hashValue
    }
}

extension UIView {
    func asImage(rect: CGRect) -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: rect)
        return renderer.image { rendererContext in
            layer.render(in: rendererContext.cgContext)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        MainView().environmentObject(LayoutViewModel())
    }
}
