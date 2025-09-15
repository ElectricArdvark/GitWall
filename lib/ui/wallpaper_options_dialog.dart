import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class WallpaperOptionsDialog extends StatelessWidget {
  final String url;
  final bool canBan;
  final bool canFavourite;
  final Function(String)? onBan;
  final Function(String)? onFavourite;
  final Function(int)? onRemoveFromList;
  final int? itemIndex;

  const WallpaperOptionsDialog({
    super.key,
    required this.url,
    this.canBan = true,
    this.canFavourite = true,
    this.onBan,
    this.onFavourite,
    this.onRemoveFromList,
    this.itemIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return ContentDialog(
          title: const Text('Wallpaper Options'),
          content: const Text('What would you like to do with this wallpaper?'),
          actions: [
            if (canBan && onBan != null)
              Tooltip(
                message: 'Ban this wallpaper',
                child: Button(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    if (onRemoveFromList != null && itemIndex != null) {
                      onRemoveFromList!(itemIndex!);
                    }
                    await onBan!(url);
                  },
                  child: const Text('Ban Wallpaper'),
                ),
              ),
            if (canFavourite && onFavourite != null)
              Tooltip(
                message: 'Add to favourites',
                child: Button(
                  onPressed: () {
                    onFavourite!(url);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Favourite'),
                ),
              ),
            Tooltip(
              message: 'Cancel',
              child: Button(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
          ],
        );
      },
    );
  }

  static void show(
    BuildContext context, {
    required String url,
    bool canBan = true,
    bool canFavourite = true,
    Function(String)? onBan,
    Function(String)? onFavourite,
    Function(int)? onRemoveFromList,
    int? itemIndex,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return WallpaperOptionsDialog(
          url: url,
          canBan: canBan,
          canFavourite: canFavourite,
          onBan: onBan,
          onFavourite: onFavourite,
          onRemoveFromList: onRemoveFromList,
          itemIndex: itemIndex,
        );
      },
    );
  }
}
