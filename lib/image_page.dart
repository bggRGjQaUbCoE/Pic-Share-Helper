import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:pic_share_helper/icon_button.dart';
import 'package:mime/mime.dart';

class ImagePage extends StatefulWidget {
  const ImagePage({
    super.key,
    required this.path,
    required this.index,
    required this.onRemove,
    required this.onUpdate,
    required this.onShare,
    required this.onSave,
  });

  final String path;
  final String index;
  final VoidCallback onRemove;
  final ValueChanged<String> onUpdate;
  final VoidCallback onShare;
  final VoidCallback onSave;

  @override
  State<ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<ImagePage>
    with AutomaticKeepAliveClientMixin {
  String? _origin;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Card(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              const SizedBox(width: 16),
              Expanded(
                  child: Text(
                widget.index,
                style: const TextStyle(fontSize: 16),
              )),
              if (_origin != null) ...[
                iconButton(
                  context: context,
                  tooltip: '恢复',
                  icon: Icons.restore,
                  onPressed: () {
                    widget.onUpdate(_origin!);
                    _origin = null;
                  },
                ),
                const SizedBox(width: 5),
              ],
              iconButton(
                context: context,
                tooltip: '分享',
                icon: Icons.share,
                onPressed: widget.onShare,
              ),
              const SizedBox(width: 5),
              iconButton(
                context: context,
                tooltip: '裁剪',
                icon: Icons.crop,
                onPressed: () {
                  String type =
                      lookupMimeType(widget.path)?.split('/').lastOrNull ??
                          'png';
                  ImageCropper().cropImage(
                    sourcePath: widget.path,
                    compressFormat: _compressFormat(type),
                    uiSettings: [
                      AndroidUiSettings(
                        toolbarTitle: '裁剪',
                        toolbarColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        toolbarWidgetColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      IOSUiSettings(
                        title: '裁剪',
                      ),
                    ],
                  ).then((file) {
                    if (file != null) {
                      _origin ??= widget.path;
                      widget.onUpdate(file.path);
                    }
                  });
                },
              ),
              const SizedBox(width: 5),
              iconButton(
                context: context,
                tooltip: '保存',
                icon: Icons.arrow_downward,
                onPressed: widget.onSave,
              ),
              const SizedBox(width: 5),
              iconButton(
                context: context,
                tooltip: '移除',
                icon: Icons.clear,
                onPressed: widget.onRemove,
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Image.file(
              File(widget.path),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  ImageCompressFormat _compressFormat(String type) => switch (type) {
        'png' => ImageCompressFormat.png,
        _ => ImageCompressFormat.jpg,
      };
}
