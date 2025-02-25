import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

const rtcAppId =
    '59535f1fe3e64f3b864ae7a55bbd3196'; //------------ Change if you need -------------
const aiModelPath = 'Resource/ModelResource.bundle';
const stickerPath =
    'Resource/StickerResource.bundle/stickers/stickers_zhaocaimao';

const licensePath =
    'Resource/agora_test_20250224_20250930_io.agora.rte.extension.bytedance.peter_4.6.2_2531.licbag';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Bytedance Extension Example'),
          backgroundColor: Colors.purple,
          foregroundColor: Colors.white,
        ),
        body: const MyHomePage(),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late final RtcEngine _rtcEngine;
  late final RtcEngineEventHandler _rtcEngineEventHandler;

  bool _isReadyPreview = false;
  bool _enableExtension = true;
  bool _enableSticker = false;

  int rtcEnginebuild = 0;

  String rtcEngineVersion = 'Loading...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    _rtcEngine.unregisterEventHandler(_rtcEngineEventHandler);
    await _rtcEngine.release();
  }

  Future<void> _init() async {
    await _requestPermissionIfNeed();
    _rtcEngine = createAgoraRtcEngine();
    await _rtcEngine.initialize(const RtcEngineContext(
      appId: rtcAppId,
      logConfig: LogConfig(level: LogLevel.logLevelInfo),
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _rtcEngineEventHandler = RtcEngineEventHandler(
      onExtensionEventWithContext:
          (ExtensionContext context, String key, String value) {
        debugPrint(
            '[onExtensionEventWithContext] ExtensionContext: $context, key: $key, value: $value');
      },
      onExtensionStartedWithContext: (ExtensionContext context) {
        debugPrint(
            '[onExtensionStartedWithContext] ExtensionContext: $context');
        if (context.providerName == 'ByteDance' &&
            context.extensionName == 'Effect') {
          _initBDExtension();
        }
      },
      onExtensionErrorWithContext:
          (ExtensionContext context, int error, String message) {
        debugPrint(
            '[onExtensionErrorWithContext] ExtensionContext: $context, error: $error, message: $message');
      },
    );
    _rtcEngine.registerEventHandler(_rtcEngineEventHandler);
    await _loadVersion();
    // if (Platform.isAndroid) {
    //   await _rtcEngine.loadExtensionProvider(
    //       path: 'AgoraByteDanceExtension', unloadAfterUse: false);
    // }

    await _rtcEngine.enableExtension(
        provider: "ByteDance", extension: "Effect", enable: _enableExtension);

    await _rtcEngine.enableVideo();
    await _rtcEngine.startPreview();

    setState(() {
      _isReadyPreview = true;
    });
  }

  Future<void> _loadVersion() async {
    var sdkversion = await _rtcEngine.getVersion();
    rtcEngineVersion = sdkversion.version ?? 'None';
    rtcEnginebuild = sdkversion.build ?? 0;
  }

  Future<String> _copyAsset(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    List<int> bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    Directory appDocDir = await getApplicationDocumentsDirectory();
    String dstPath = path.join(appDocDir.path, path.basename(assetPath));
    File file = File(dstPath);
    if (!(await file.exists())) {
      await file.create();
      await file.writeAsBytes(bytes);
    }

    return file.absolute.path;
  }

  Future<String> _copyFolder(String assetFolderPath) async {
    // 获取文档目录路径
    Directory appDocDir = await getApplicationDocumentsDirectory();

    // 目标文件夹的路径
    final dirname = path.basename(assetFolderPath);
    Directory dstDir = Directory(path.join(appDocDir.path, dirname));

    // 从 AssetManifest.json 中获取资源文件列表
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final assetsInFolder = manifestMap.keys
        .where((String key) => key.startsWith(assetFolderPath))
        .toList();

    // 遍历所有文件，复制到目标文件夹
    for (String asset in assetsInFolder) {
      ByteData data = await rootBundle.load(asset);
      List<int> bytes = data.buffer.asUint8List();

      String relativePath = path.relative(asset, from: assetFolderPath);
      String targetPath = path.join(dstDir.path, relativePath);
      File targetFile = File(targetPath);

      if (!(await targetFile.exists())) {
        await targetFile.create(recursive: true);
        await targetFile.writeAsBytes(bytes);
      }
    }

    return dstDir.absolute.path;
  }

  Future<void> _requestPermissionIfNeed() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await [Permission.microphone, Permission.camera].request();
    }
  }

  Future<void> _loadAIModels() async {
    final aiModelRealPath = await _copyFolder(aiModelPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'ByteDance',
        extension: 'Effect',
        key: 'bef_effect_ai_init',
        value: jsonEncode({'strModelDir': aiModelRealPath, 'deviceName': ''}));
  }

  Future<void> _enableStickerEffect() async {
    final stickerRealPath = await _copyFolder(stickerPath);
    await _rtcEngine.setExtensionProperty(
        provider: 'ByteDance',
        extension: 'Effect',
        key: 'bef_effect_ai_set_effect',
        value: jsonEncode({'strPath': stickerRealPath}));
  }

  Future<void> _disableStickerEffect() async {
    await _rtcEngine.setExtensionProperty(
        provider: 'ByteDance',
        extension: 'Effect',
        key: 'bef_effect_ai_set_effect',
        value: jsonEncode({'strPath': ''}));
  }

  Future<void> _initBDExtension() async {
    final licenseRealPath = await _copyAsset(licensePath);
    await _rtcEngine.setExtensionProperty(
        provider: 'ByteDance',
        extension: 'Effect',
        key: 'bef_effect_ai_check_license',
        value: jsonEncode({'licensePath': licenseRealPath}));

    await _loadAIModels();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReadyPreview) {
      return Container();
    }

    return Stack(
      alignment: AlignmentDirectional.bottomEnd,
      children: [
        AgoraVideoView(
            controller: VideoViewController(
          rtcEngine: _rtcEngine,
          canvas: const VideoCanvas(uid: 0),
        )),
        Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(flex: 1, child: Container()),
            Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Agora RTC SDK: $rtcEngineVersion($rtcEnginebuild)',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.blue),
                  onPressed: () async {
                    setState(() {
                      _enableExtension = !_enableExtension;
                    });

                    await _rtcEngine.enableExtension(
                        provider: "ByteDance",
                        extension: "Effect",
                        enable: _enableExtension);
                  },
                  child: Text(_enableExtension
                      ? 'disableExtension'
                      : 'enableExtension'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.yellow),
                  onPressed: () async {
                    setState(() {
                      _enableSticker = !_enableSticker;
                    });

                    if (_enableSticker) {
                      await _enableStickerEffect();
                    } else {
                      await _disableStickerEffect();
                    }
                  },
                  child:
                      Text(_enableSticker ? 'disableSticker' : 'enableSticker'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
