import 'dart:async';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pic_share_helper/cache_util.dart';
import 'package:pic_share_helper/custom_toast.dart';
import 'package:pic_share_helper/icon_button.dart';
import 'package:pic_share_helper/image_page.dart';
import 'package:pic_share_helper/config_model.dart';
import 'package:pic_share_helper/path.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mime/mime.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );
  await CacheManage.clearLibraryCache();
  runApp(const PicShareHelper());
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    statusBarColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
    systemStatusBarContrastEnforced: false,
  ));
}

class PicShareHelper extends StatelessWidget {
  const PicShareHelper({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        ColorScheme colorSchemeLight;
        ColorScheme colorSchemeDark;
        if (lightDynamic != null && darkDynamic != null) {
          colorSchemeLight = lightDynamic;
          colorSchemeDark = darkDynamic;
        } else {
          colorSchemeLight = ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
          );
          colorSchemeDark = ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: Colors.deepPurple,
          );
        }
        return MaterialApp(
          title: 'Pic Share Helper',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: colorSchemeLight,
            dialogTheme: DialogTheme(
              surfaceTintColor: colorSchemeLight.surfaceTint,
            ),
            cardTheme: CardTheme(
              shadowColor: Colors.transparent,
              surfaceTintColor: colorSchemeLight.surfaceTint,
            ),
            bottomAppBarTheme: BottomAppBarTheme(
              surfaceTintColor: colorSchemeDark.surfaceTint,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: colorSchemeDark,
            dialogTheme: DialogTheme(
              surfaceTintColor: colorSchemeDark.surfaceTint,
            ),
            cardTheme: CardTheme(
              shadowColor: Colors.transparent,
              surfaceTintColor: colorSchemeDark.surfaceTint,
            ),
            bottomAppBarTheme: BottomAppBarTheme(
              surfaceTintColor: colorSchemeDark.surfaceTint,
            ),
          ),
          home: const MainPage(),
          builder: (BuildContext context, Widget? child) {
            return FlutterSmartDialog(
              toastBuilder: (String msg) => CustomToast(msg: msg),
              child: child,
            );
          },
        );
      },
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const String _appName = 'Pic Share Helper';
  static const String _sourceCodeUrl =
      'https://github.com/bggRGjQaUbCoE/Pic-Share-Helper';

  late final StreamSubscription _intentSub;
  final List<Path> _paths = <Path>[];

  bool _isPicking = false;
  late final _imagePicker = ImagePicker();

  late final _controller = PageController(viewportFraction: 0.9);

  bool _isGlobal = true;
  final ConfigModel _globalConfig = ConfigModel();
  final List<ConfigModel> _configList = [];
  final StreamController<int> _indexStream = StreamController();

  int get _currentIndex => (_controller.page?.round()) ?? 0;
  ConfigModel get _currentConfig =>
      _isGlobal || _paths.isEmpty ? _globalConfig : _configList[_currentIndex];

  @override
  void initState() {
    super.initState();

    // Listen to media sharing coming from outside the app while the app is in the memory.
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> files) {
        if (files.isNotEmpty) {
          setState(() {
            _paths.addAll(files.map((item) => Path(item.path, null)).toList());
            _configList
                .addAll(List.generate(files.length, (_) => ConfigModel()));
          });
        }
      },
      onError: (err) {
        debugPrint("getIntentDataStream error: $err");
      },
    );

    // Get the media sharing coming from outside the app while the app is closed.
    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> files) {
      if (files.isNotEmpty) {
        setState(() {
          _paths.addAll(files.map((item) => Path(item.path, null)).toList());
          _configList.addAll(List.generate(files.length, (_) => ConfigModel()));
        });
      }
      ReceiveSharingIntent.instance.reset();
    });
  }

  @override
  void dispose() {
    _indexStream.close();
    _intentSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: _leading,
        titleSpacing: 5,
        title: const Text(
          _appName,
          style: TextStyle(fontSize: 18),
        ),
        actions: _actions,
      ),
      bottomNavigationBar: _bottomNavigationBar,
      floatingActionButton: _floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      body: _paths.isNotEmpty ? _buildBody : _emptyView,
    );
  }

  Widget get _buildBody => Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: PageView(
          controller: _controller,
          onPageChanged: (index) {
            _indexStream.add(index);
          },
          children: List.generate(
            _paths.length,
            (index) => ImagePage(
              path: _paths[index],
              index: '${index + 1}/${_paths.length}',
              onRemove: () {
                setState(() {
                  _paths.removeAt(index);
                  _configList.removeAt(index);
                });
              },
              onUpdate: (path) {
                setState(() {
                  _paths[index].cropped = path;
                });
              },
              onShare: () => _onShare([_paths[index]]),
              onSave: () => _onSave([_paths[index]]),
            ),
          ),
        ),
      );

  Widget get _bottomNavigationBar => StreamBuilder(
      stream: _indexStream.stream,
      builder: (_, snapshot) {
        return Card(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            constraints: const BoxConstraints(minHeight: 95),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _isGlobal = !_isGlobal;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _isGlobal,
                        onChanged: (value) {
                          setState(() {
                            _isGlobal = !_isGlobal;
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('全局配置'),
                    ],
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      _currentConfig.removeExif = !_currentConfig.removeExif;
                    });
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _currentConfig.removeExif,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _currentConfig.removeExif = value;
                            });
                          }
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const Text('移除 EXIF'),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    const Text('图片画质'),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: 100,
                        divisions: 99,
                        value: _currentConfig.quality,
                        onChanged: (value) {
                          setState(() {
                            _currentConfig.quality = value;
                          });
                        },
                      ),
                    ),
                    Text(
                      _currentConfig.quality.round().toString(),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.paddingOf(context).bottom)
              ],
            ),
          ),
        );
      });

  List<Widget> get _actions => [
        IconButton(
          onPressed: () => _onShare(_paths),
          iconSize: 20,
          tooltip: '分享全部',
          icon: const Icon(Icons.share),
        ),
        IconButton(
          onPressed: () => _onSave(_paths),
          iconSize: 20,
          tooltip: '保存全部',
          icon: const Icon(Icons.save_alt_outlined),
        ),
        IconButton(
          onPressed: () {
            if (_paths.isNotEmpty) {
              setState(() {
                _paths.clear();
                _configList.clear();
              });
            }
          },
          iconSize: 20,
          tooltip: '清除全部',
          icon: const Icon(Icons.clear_all),
        ),
        const SizedBox(width: 16),
      ];

  FloatingActionButton get _floatingActionButton => FloatingActionButton(
        tooltip: '添加',
        child: const Icon(Icons.add),
        onPressed: () {
          if (_isPicking) return;
          _isPicking = true;
          _imagePicker.pickMultiImage(imageQuality: 100).then((files) {
            if (files.isNotEmpty) {
              setState(() {
                _paths.addAll(
                    files.map((item) => Path(item.path, null)).toList());
                _configList
                    .addAll(List.generate(files.length, (_) => ConfigModel()));
              });
            }
            _isPicking = false;
          });
        },
      );

  Widget get _leading => Container(
        alignment: Alignment.center,
        margin: const EdgeInsets.only(left: 14),
        child: iconButton(
          context: context,
          tooltip: _appName,
          icon: Icons.image_outlined,
          onPressed: _showAboutDialog,
        ),
      );

  void _showAboutDialog() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Row(
            children: [
              iconButton(
                context: context,
                tooltip: _appName,
                icon: Icons.image_outlined,
                onPressed: () {},
              ),
              const SizedBox(width: 10),
              const Text(
                _appName,
                style: TextStyle(fontSize: 20),
              ),
            ],
          ),
          content: Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Source Code: '),
                TextSpan(
                  text: 'GitHub',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      try {
                        Navigator.of(context).pop();
                        launchUrl(
                          Uri.parse(_sourceCodeUrl),
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        debugPrint('failed to launch url: $e');
                      }
                    },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text(
                'Close',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );

  Widget get _emptyView => const Center(
        child: Text(
          'EMPTY',
          style: TextStyle(fontSize: 16),
        ),
      );

  void _onShare(List<Path> paths) async {
    if (_paths.isNotEmpty) {
      try {
        List<XFile> files = [];
        for (int i = 0; i < paths.length; i++) {
          SmartDialog.showLoading(
            msg:
                'processing${paths.length > 1 ? ' ${i + 1}/${paths.length}' : ''}',
          );
          String type =
              lookupMimeType(paths[i].valid)?.split('/').lastOrNull ?? 'png';
          await FlutterImageCompress.compressAndGetFile(
            paths[i].valid,
            '${paths[i].valid}${DateTime.now().millisecondsSinceEpoch}.$type',
            quality: _currentConfig.quality.round(),
            keepExif: !_currentConfig.removeExif,
            format: _compressFormat(type),
          ).then((file) {
            if (file != null) {
              files.add(file);
            }
          });
        }
        SmartDialog.dismiss();
        if (files.isNotEmpty) {
          Share.shareXFiles(files);
        }
      } catch (e) {
        SmartDialog.dismiss();
        SmartDialog.showToast(e.toString());
      }
    }
  }

  void _onSave(List<Path> paths) async {
    if (paths.isNotEmpty) {
      try {
        for (int i = 0; i < paths.length; i++) {
          SmartDialog.showLoading(
            msg:
                'processing${paths.length > 1 ? ' ${i + 1}/${paths.length}' : ''}',
          );
          String type =
              lookupMimeType(paths[i].valid)?.split('/').lastOrNull ?? 'png';
          await FlutterImageCompress.compressWithFile(
            paths[i].valid,
            quality: _currentConfig.quality.round(),
            keepExif: !_currentConfig.removeExif,
            format: _compressFormat(type),
          ).then((data) {
            if (data != null) {
              String imageName = paths[i].valid.split('/').lastOrNull ??
                  '${DateTime.now().millisecondsSinceEpoch ~/ 1000}.jpg';
              SaverGallery.saveImage(
                data,
                quality: 100,
                fileName: imageName,
                androidRelativePath: "Pictures/PicShareHelper",
                skipIfExists: false,
              ).then((result) {
                if (result.isSuccess) {
                  SmartDialog.showToast('保存成功');
                } else {
                  SmartDialog.showToast(result.errorMessage ?? '保存失败');
                }
              });
            }
          });
        }
        SmartDialog.dismiss();
      } catch (e) {
        SmartDialog.dismiss();
        SmartDialog.showToast(e.toString());
      }
    }
  }

  CompressFormat _compressFormat(String type) => switch (type) {
        'png' => CompressFormat.png,
        'heic' => CompressFormat.heic,
        'webp' => CompressFormat.webp,
        _ => CompressFormat.jpeg,
      };
}
