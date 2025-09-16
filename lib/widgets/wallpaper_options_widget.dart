import 'package:fluent_ui/fluent_ui.dart' hide Colors;
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../buttons/favourite_button.dart';
import '../buttons/ban_button.dart';

class WallpaperOptionsDialog extends StatelessWidget {
  final String url;
  final bool canBan;
  final bool canFavourite;
  final bool canDelete;
  final Function(String)? onBan;
  final Function(String)? onFavourite;
  final Function(int)? onRemoveFromList;
  final int? itemIndex;

  const WallpaperOptionsDialog({
    super.key,
    required this.url,
    this.canBan = true,
    this.canFavourite = true,
    this.canDelete = false,
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
            if (canDelete && onRemoveFromList != null && itemIndex != null)
              Tooltip(
                message: 'Delete this wallpaper',
                child: Button(
                  onPressed: () {
                    onRemoveFromList!(itemIndex!);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Delete'),
                ),
              ),
            if (canBan && onBan != null)
              BanButton(
                url: url,
                onBan: (url) async {
                  if (onRemoveFromList != null && itemIndex != null) {
                    onRemoveFromList!(itemIndex!);
                  }
                  await onBan!(url);
                },
                canBan: canBan,
              ),
            if (canFavourite && onFavourite != null)
              FavouriteButton(
                url: url,
                onFavourite: onFavourite!,
                canFavourite: canFavourite,
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
    bool canDelete = false,
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
          canDelete: canDelete,
          onBan: onBan,
          onFavourite: onFavourite,
          onRemoveFromList: onRemoveFromList,
          itemIndex: itemIndex,
        );
      },
    );
  }
}
