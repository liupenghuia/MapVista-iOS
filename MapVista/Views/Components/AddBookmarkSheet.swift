import SwiftUI
import CoreLocation

struct AddBookmarkSheet: View {
    let coordinate: CLLocationCoordinate2D
    let onConfirm: (String, POICategory) -> Void
    let onCancel: () -> Void
    
    @State private var remark: String = ""
    @State private var selectedCategory: POICategory? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("📍 添加位置收藏")
                .font(.system(size: 20, weight: .bold))
                .padding(.top, 16)
            
            // Coordinate Info
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("当前经纬度")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(String(format: "经度 %.5f, 纬度 %.5f", coordinate.longitude, coordinate.latitude))
                        .font(.system(size: 16, weight: .medium, design: .monospaced))
                }
                Spacer()
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
            
            // Category Selection
            VStack(alignment: .leading, spacing: 8) {
                Text("标签分类 (必选选项)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(POICategory.allCases) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: category.iconName)
                                        .font(.system(size: 12))
                                    Text(category.displayName)
                                }
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                                .background(selectedCategory == category ? Color.systemTeal : Color(UIColor.secondarySystemBackground))
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }
            
            // Input Field
            VStack(alignment: .leading, spacing: 8) {
                Text("位置备注")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("备选填：请输入该位置的备注/名称...", text: $remark)
                    .padding(14)
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(12)
                    .font(.system(size: 16))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button(action: onCancel) {
                    Text("取消")
                        .font(.system(size: 16, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(UIColor.secondarySystemBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    guard let cat = selectedCategory else { return }
                    onConfirm(remark.isEmpty ? "自定义位置" : remark, cat)
                }) {
                    Text("确认标记")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(selectedCategory == nil ? Color(UIColor.systemGray4) : Color.systemTeal)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: selectedCategory == nil ? .clear : Color.systemTeal.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(selectedCategory == nil)
            }
            .padding(.bottom, 8)
        }
        .padding(24)
    }
}
