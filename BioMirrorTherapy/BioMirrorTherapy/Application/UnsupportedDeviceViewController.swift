//
//  UnsupportedDeviceViewController.swift
//  BioMirrorTherapy
//
//  Created by Mykhailo Kotyk on 31.03.2025.
//

import UIKit

class UnsupportedDeviceViewController: UIViewController {
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "exclamationmark.triangle.fill"))
        imageView.tintColor = .systemRed
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Unsupported Device"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "This app requires a device with Face ID or LiDAR capabilities to function properly. Please use a compatible device."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let capabilitiesLabel: UILabel = {
        let label = UILabel()
        label.text = "Required capabilities:\n• Face tracking\n• LiDAR Scanner\n• ARKit 4+ support"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let continueAnywayButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue Anyway (Limited Functionality)", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemGray5
        button.setTitleColor(.systemBlue, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupConstraints()
        setupActions()
    }
    
    private func setupView() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(messageLabel)
        view.addSubview(capabilitiesLabel)
        view.addSubview(continueAnywayButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            iconImageView.widthAnchor.constraint(equalToConstant: 100),
            iconImageView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            capabilitiesLabel.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 40),
            capabilitiesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            capabilitiesLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            continueAnywayButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            continueAnywayButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueAnywayButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            continueAnywayButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            continueAnywayButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupActions() {
        continueAnywayButton.addTarget(self, action: #selector(continueAnywayTapped), for: .touchUpInside)
    }
    
    @objc private func continueAnywayTapped() {
        // In a real implementation, this would notify the app coordinator to continue with limited functionality
        print("Continue anyway tapped - would proceed with limited functionality")
        
        // Show an alert explaining the limitations
        let alert = UIAlertController(
            title: "Limited Functionality",
            message: "The app will operate with limited features. Facial emotion tracking and certain therapeutic activities will not be available.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Continue", style: .default, handler: { _ in
            // Notify the app coordinator (would be implemented in a real app)
            NotificationCenter.default.post(name: NSNotification.Name("ContinueWithLimitedFunctionality"), object: nil)
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}