import SwiftUI
import WidgetKit

#if WIDGET_EXTENSION
@main
struct PulseWidgetBundle: WidgetBundle {
    var body: some Widget {
        PulseWidget()
    }
}
#endif
