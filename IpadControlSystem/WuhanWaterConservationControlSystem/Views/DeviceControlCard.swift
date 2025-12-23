//
//  DeviceControlCard.swift
//  WuhanWaterConservationControlSystem
//
//  Created by SOLO Builder on 2025/12/23.
//  Copyright © 2025 WuhanWaterConservation. All rights reserved.
//

import UIKit

class DeviceControlCard: UIView {
    
    // MARK: - UI Components
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let indicatorView = UIView()
    
    // MARK: - Properties
    
    private var deviceType: DeviceType = .lighting
    private var cardColor: UIColor = UIColor(red: 0.0, green: 122.0/255.0, blue: 1.0, alpha: 1.0)
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .white
        layer.cornerRadius = 12
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.1
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        setupIconImageView()
        setupLabels()
        setupIndicator()
        setupConstraints()
    }
    
    private func setupIconImageView() {
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = cardColor
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            // 使用SF Symbols
        } else {
            // iOS 10兼容性处理
            iconImageView.image = UIImage(named: "default_icon")
        }
        
        addSubview(iconImageView)
    }
    
    private func setupLabels() {
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .darkText
        titleLabel.textAlignment = .left
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
    }
    
    private func setupIndicator() {
        indicatorView.backgroundColor = .lightGray
        indicatorView.layer.cornerRadius = 4
        indicatorView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(indicatorView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // 图标
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 24),
            iconImageView.heightAnchor.constraint(equalToConstant: 24),
            
            // 标题
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            // 指示器
            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            indicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            indicatorView.widthAnchor.constraint(equalToConstant: 8),
            indicatorView.heightAnchor.constraint(equalToConstant: 8),
            
            // 卡片最小高度
            heightAnchor.constraint(equalToConstant: 120)
        ])
    }
    
    // MARK: - Public Methods
    
    func configure(title: String, icon: String, deviceType: DeviceType, color: UIColor) {
        self.deviceType = deviceType
        self.cardColor = color
        
        titleLabel.text = title
        iconImageView.tintColor = color
        
        if #available(iOS 13.0, *) {
            iconImageView.image = UIImage(systemName: icon)
        } else {
            // iOS 10兼容性处理
            iconImageView.image = createFallbackIcon(for: deviceType)
        }
    }
    
    func updateStatus(onlineCount: Int, totalCount: Int) {
        if onlineCount == totalCount && totalCount > 0 {
            indicatorView.backgroundColor = UIColor(red: 52.0/255.0, green: 199.0/255.0, blue: 89.0/255.0, alpha: 1.0)
        } else if onlineCount > 0 {
            indicatorView.backgroundColor = UIColor(red: 255.0/255.0, green: 204.0/255.0, blue: 0.0/255.0, alpha: 1.0)
        } else {
            indicatorView.backgroundColor = .red
        }
    }
    
    // MARK: - Private Methods
    
    private func createFallbackIcon(for deviceType: DeviceType) -> UIImage? {
        // iOS 10兼容性：创建简单的图形图标
        let size = CGSize(width: 24, height: 24)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(cardColor.cgColor)
        context.setStrokeColor(cardColor.cgColor)
        
        switch deviceType {
        case .lighting:
            // 绘制灯泡形状
            let rect = CGRect(x: 8, y: 4, width: 8, height: 12)
            context.fillEllipse(in: rect)
            context.fill(CGRect(x: 6, y: 16, width: 12, height: 4))
            
        case .computer:
            // 绘制显示器形状
            context.fill(CGRect(x: 4, y: 6, width: 16, height: 10))
            context.fill(CGRect(x: 8, y: 16, width: 8, height: 2))
            
        case .projector:
            // 绘制投影仪形状
            context.fillEllipse(in: CGRect(x: 6, y: 8, width: 12, height: 8))
            
        case .exhibitPower:
            // 绘制电源形状
            context.fillEllipse(in: CGRect(x: 6, y: 6, width: 12, height: 12))
            context.setFillColor(UIColor.white.cgColor)
            context.fill(CGRect(x: 10, y: 10, width: 4, height: 4))
        }
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - Extensions

extension DeviceControlCard {
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        // 按下效果
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            self.layer.shadowOpacity = 0.2
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        // 释放效果
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.layer.shadowOpacity = 0.1
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        // 取消效果
        UIView.animate(withDuration: 0.1) {
            self.transform = .identity
            self.layer.shadowOpacity = 0.1
        }
    }
}
