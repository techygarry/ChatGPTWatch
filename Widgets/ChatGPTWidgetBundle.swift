import WidgetKit
import SwiftUI

@main
struct ChatGPTWidgetBundle: WidgetBundle {
    var body: some Widget {
        ChatGPTCircularWidget()
        ChatGPTRectangularWidget()
        ChatGPTInlineWidget()
    }
}
