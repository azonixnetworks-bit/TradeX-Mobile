import Flutter
import LocalAuthentication
import Security
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(
      forPlugin: "TradeXDeviceCredential"
    )
    let channel = FlutterMethodChannel(
      name: "com.azonixnetworks.tradex_mobile/device_credential",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleDeviceCredential(call: call, result: result)
    }
  }

  private func handleDeviceCredential(
    call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let credentialId = arguments["credentialId"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENT", message: "credentialId is required", details: nil))
      return
    }

    do {
      switch call.method {
      case "createCredential":
        let requireBiometric = arguments["requireBiometric"] as? Bool ?? false
        let publicKey = try createCredential(
          credentialId: credentialId,
          requireBiometric: requireBiometric
        )
        result(["publicKey": publicKey, "algorithm": "ES256"])
      case "sign":
        guard let message = arguments["message"] as? String else {
          throw DeviceCredentialError.invalidArgument
        }
        result(try sign(credentialId: credentialId, message: message))
      case "containsCredential":
        result(loadPrivateKey(credentialId: credentialId, context: nil) != nil)
      case "deleteCredential":
        deleteCredential(credentialId: credentialId)
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    } catch {
      result(FlutterError(
        code: "DEVICE_CREDENTIAL_ERROR",
        message: error.localizedDescription,
        details: nil
      ))
    }
  }

  private func createCredential(
    credentialId: String,
    requireBiometric: Bool
  ) throws -> String {
    deleteCredential(credentialId: credentialId)
    let tag = credentialTag(credentialId)
    var flags: SecAccessControlCreateFlags = [.privateKeyUsage]
    if requireBiometric { flags.insert(.biometryCurrentSet) }

    var accessError: Unmanaged<CFError>?
    guard let access = SecAccessControlCreateWithFlags(
      nil,
      kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
      flags,
      &accessError
    ) else {
      throw accessError!.takeRetainedValue()
    }

    let privateAttributes: [String: Any] = [
      kSecAttrIsPermanent as String: true,
      kSecAttrApplicationTag as String: tag,
      kSecAttrAccessControl as String: access,
    ]
    var attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256,
      kSecPrivateKeyAttrs as String: privateAttributes,
      kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
    ]

    var keyError: Unmanaged<CFError>?
    var privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &keyError)
    if privateKey == nil {
      // Simulator and older supported devices may not expose Secure Enclave;
      // Keychain still keeps the key non-exported from Flutter application code.
      attributes.removeValue(forKey: kSecAttrTokenID as String)
      privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &keyError)
    }
    guard let privateKey, let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw keyError?.takeRetainedValue() ?? DeviceCredentialError.creationFailed
    }

    var exportError: Unmanaged<CFError>?
    guard let external = SecKeyCopyExternalRepresentation(publicKey, &exportError) as Data? else {
      throw exportError!.takeRetainedValue()
    }

    // Security.framework returns the uncompressed P-256 point. Laravel/OpenSSL
    // consumes the standard SubjectPublicKeyInfo wrapper used by Android too.
    let prefix = Data([
      0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2A, 0x86, 0x48, 0xCE,
      0x3D, 0x02, 0x01, 0x06, 0x08, 0x2A, 0x86, 0x48, 0xCE, 0x3D,
      0x03, 0x01, 0x07, 0x03, 0x42, 0x00,
    ])
    return (prefix + external).base64EncodedString()
  }

  private func sign(credentialId: String, message: String) throws -> String {
    let context = LAContext()
    context.localizedReason = "Verify your identity to unlock TradeX."
    guard let privateKey = loadPrivateKey(credentialId: credentialId, context: context) else {
      throw DeviceCredentialError.missing
    }
    let algorithm = SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256
    guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
      throw DeviceCredentialError.unsupported
    }
    var error: Unmanaged<CFError>?
    guard let signature = SecKeyCreateSignature(
      privateKey,
      algorithm,
      Data(message.utf8) as CFData,
      &error
    ) as Data? else {
      throw error!.takeRetainedValue()
    }
    return signature.base64EncodedString()
  }

  private func loadPrivateKey(credentialId: String, context: LAContext?) -> SecKey? {
    var query: [String: Any] = [
      kSecClass as String: kSecClassKey,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrApplicationTag as String: credentialTag(credentialId),
      kSecReturnRef as String: true,
    ]
    if let context { query[kSecUseAuthenticationContext as String] = context }
    var item: CFTypeRef?
    guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess else {
      return nil
    }
    return (item as! SecKey)
  }

  private func deleteCredential(credentialId: String) {
    SecItemDelete([
      kSecClass as String: kSecClassKey,
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrApplicationTag as String: credentialTag(credentialId),
    ] as CFDictionary)
  }

  private func credentialTag(_ credentialId: String) -> Data {
    Data("com.azonixnetworks.tradex.quick.\(credentialId.lowercased())".utf8)
  }
}

private enum DeviceCredentialError: LocalizedError {
  case invalidArgument, creationFailed, missing, unsupported

  var errorDescription: String? {
    switch self {
    case .invalidArgument: return "The device credential request is invalid."
    case .creationFailed: return "The protected device credential could not be created."
    case .missing: return "The protected device credential is missing."
    case .unsupported: return "This device does not support secure credential signing."
    }
  }
}
