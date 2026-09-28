import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../../constants/app_colors.dart';

/// Layout modes [SmartSkeleton] knows how to render.
enum SkeletonLayout {
  /// A row (or wrapped grid) of small, uniform tiles — trade icons,
  /// category chips, avatar rows, filter pills.
  grid,

  /// A vertical column of bigger composite cards — job postings, feed
  /// items, list rows with a leading icon + title + meta + tags.
  list,

  /// A single inline row of "stat" blocks — a big value bone stacked
  /// over a small label bone, evenly spaced. Good for stat bars.
  row,

  /// You supply the per-item layout via [itemBuilder]; SmartSkeleton just
  /// handles count/spacing/scaffolding and the shimmer wrapper.
  custom,
}

/// One versatile, parameter-driven skeleton loader for the whole app.
///
/// Instead of hand-building a bespoke skeleton widget for every section,
/// describe the section's *shape* once via constructor params and reuse it
/// anywhere a list/grid/stat-row loads data:
///
/// ```dart
/// // small grid — e.g. "Browse by Trade"
/// SmartSkeleton.grid(
///   enabled: isLoading,
///   itemCount: 8,
///   itemWidth: 84,
///   itemHeight: 90,
///   hasLabel: true,
/// )
///
/// // bigger cards — e.g. job postings list
/// SmartSkeleton.list(
///   enabled: isLoading,
///   itemCount: 4,
///   hasLeading: true,
///   tagCount: 3,
/// )
///
/// // inline stat bar
/// SmartSkeleton.row(enabled: isLoading, itemCount: 3)
///
/// // fully custom item shape, SmartSkeleton just handles the shell
/// SmartSkeleton.custom(
///   enabled: isLoading,
///   itemCount: 5,
///   itemBuilder: (context, i) => MyCustomBoneLayout(),
/// )
/// ```
///
/// Drive [enabled] off your loading flag. When it flips to `false`, swap
/// this widget out for the real content — SmartSkeleton doesn't hold data,
/// it only mimics shape.
class SmartSkeleton extends StatelessWidget {
  final SkeletonLayout layout;
  final bool enabled;
  final int itemCount;

  // grid
  final Axis scrollDirection;
  final double itemWidth;
  final double itemHeight;
  final bool hasLabel;
  final BoxShape gridTileShape;

  // list
  final bool hasLeading;
  final double leadingSize;
  final bool leadingIsCircle;
  final int titleWords;
  final int subtitleWords;
  final bool hasMeta;
  final bool hasTags;
  final int tagCount;
  final double tagWidth;
  final double tagHeight;

  // row (stat bar)
  final bool showRowLabel;

  // shared
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry itemMargin;
  final EdgeInsetsGeometry itemPadding;
  final double borderRadius;
  final bool showCardChrome;

  // custom
  final Widget Function(BuildContext context, int index)? itemBuilder;

  const SmartSkeleton.grid({
    super.key,
    this.enabled = true,
    this.itemCount = 6,
    this.scrollDirection = Axis.horizontal,
    this.itemWidth = 84,
    this.itemHeight = 90,
    this.hasLabel = true,
    this.gridTileShape = BoxShape.circle,
    this.spacing = 10,
    this.runSpacing = 10,
    this.padding = EdgeInsets.zero,
    this.borderRadius = 12,
    this.showCardChrome = true,
  }) : layout = SkeletonLayout.grid,
       hasLeading = false,
       leadingSize = 0,
       leadingIsCircle = false,
       titleWords = 0,
       subtitleWords = 0,
       hasMeta = false,
       hasTags = false,
       tagCount = 0,
       tagWidth = 0,
       tagHeight = 0,
       showRowLabel = false,
       itemMargin = EdgeInsets.zero,
       itemPadding = const EdgeInsets.symmetric(vertical: 10),
       itemBuilder = null;

  const SmartSkeleton.list({
    super.key,
    this.enabled = true,
    this.itemCount = 4,
    this.hasLeading = true,
    this.leadingSize = 44,
    this.leadingIsCircle = false,
    this.titleWords = 3,
    this.subtitleWords = 2,
    this.hasMeta = true,
    this.hasTags = true,
    this.tagCount = 3,
    this.tagWidth = 60,
    this.tagHeight = 20,
    this.spacing = 12,
    this.padding = EdgeInsets.zero,
    this.itemMargin = const EdgeInsets.only(bottom: 12),
    this.itemPadding = const EdgeInsets.all(14),
    this.borderRadius = 14,
    this.showCardChrome = true,
  }) : layout = SkeletonLayout.list,
       scrollDirection = Axis.vertical,
       itemWidth = 0,
       itemHeight = 0,
       hasLabel = false,
       gridTileShape = BoxShape.circle,
       runSpacing = 0,
       showRowLabel = false,
       itemBuilder = null;

  const SmartSkeleton.row({
    super.key,
    this.enabled = true,
    this.itemCount = 3,
    this.showRowLabel = true,
    this.spacing = 16,
    this.padding = EdgeInsets.zero,
    this.itemPadding = EdgeInsets.zero,
    this.borderRadius = 14,
    this.showCardChrome = true,
  }) : layout = SkeletonLayout.row,
       scrollDirection = Axis.horizontal,
       itemWidth = 0,
       itemHeight = 0,
       hasLabel = false,
       gridTileShape = BoxShape.circle,
       runSpacing = 0,
       hasLeading = false,
       leadingSize = 0,
       leadingIsCircle = false,
       titleWords = 0,
       subtitleWords = 0,
       hasMeta = false,
       hasTags = false,
       tagCount = 0,
       tagWidth = 0,
       tagHeight = 0,
       itemMargin = EdgeInsets.zero,
       itemBuilder = null;

  const SmartSkeleton.custom({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.enabled = true,
    this.scrollDirection = Axis.vertical,
    this.spacing = 12,
    this.padding = EdgeInsets.zero,
  }) : layout = SkeletonLayout.custom,
       itemWidth = 0,
       itemHeight = 0,
       hasLabel = false,
       gridTileShape = BoxShape.circle,
       runSpacing = 0,
       hasLeading = false,
       leadingSize = 0,
       leadingIsCircle = false,
       titleWords = 0,
       subtitleWords = 0,
       hasMeta = false,
       hasTags = false,
       tagCount = 0,
       tagWidth = 0,
       tagHeight = 0,
       showRowLabel = false,
       itemMargin = EdgeInsets.zero,
       itemPadding = EdgeInsets.zero,
       borderRadius = 12,
       showCardChrome = false;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE0E0E0),
        highlightColor: Color(0xFFF5F5F5),
      ),
      child: Padding(
        padding: padding,
        child: switch (layout) {
          SkeletonLayout.grid => _buildGrid(),
          SkeletonLayout.list => _buildList(),
          SkeletonLayout.row => _buildRow(),
          SkeletonLayout.custom => _buildCustom(context),
        },
      ),
    );
  }

  // ---------------------------------------------------------------------
  // GRID — small uniform tiles, scrollable row or wrapped grid.
  // ---------------------------------------------------------------------
  Widget _buildGrid() {
    if (scrollDirection == Axis.horizontal) {
      return SizedBox(
        height: itemHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, __) => SizedBox(width: spacing),
          itemBuilder: (context, i) => _gridTile(),
        ),
      );
    }
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      children: List.generate(itemCount, (i) => _gridTile()),
    );
  }

  Widget _gridTile() {
    final tile = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        gridTileShape == BoxShape.circle
            ? const Bone.circle(size: 26)
            : Bone.square(size: 26),
        if (hasLabel) ...[const SizedBox(height: 6), const Bone.text(words: 1)],
      ],
    );

    if (!showCardChrome) {
      return SizedBox(width: itemWidth, child: tile);
    }

    return Container(
      width: itemWidth,
      padding: itemPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: tile,
    );
  }

  // ---------------------------------------------------------------------
  // LIST — bigger composite cards stacked vertically.
  // ---------------------------------------------------------------------
  Widget _buildList() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(children: List.generate(itemCount, (i) => _listCard())),
    );
  }

  Widget _listCard() {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasLeading) ...[
              leadingIsCircle
                  ? Bone.circle(size: leadingSize)
                  : Bone.square(size: leadingSize),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Bone.text(words: titleWords),
                  const SizedBox(height: 6),
                  Bone.text(words: subtitleWords),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Bone.text(words: 1),
          ],
        ),
        if (hasMeta) ...[
          const SizedBox(height: 10),
          Row(
            children: const [
              Bone.icon(size: 15),
              SizedBox(width: 4),
              Bone.text(words: 2),
              SizedBox(width: 14),
              Bone.icon(size: 15),
              SizedBox(width: 4),
              Bone.text(words: 1),
            ],
          ),
        ],
        if (hasTags) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(
              tagCount,
              (i) => Bone(width: tagWidth, height: tagHeight),
            ),
          ),
        ],
      ],
    );

    if (!showCardChrome) {
      return Padding(padding: itemMargin, child: content);
    }

    return Container(
      margin: itemMargin,
      padding: itemPadding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: content,
    );
  }

  // ---------------------------------------------------------------------
  // ROW — inline stat blocks (big value over small label), evenly spaced.
  // ---------------------------------------------------------------------
  Widget _buildRow() {
    final row = Row(
      children: List.generate(
        itemCount,
        (i) => Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spacing / 2),
            child: Column(
              children: [
                const Bone.text(words: 1),
                if (showRowLabel) ...[
                  const SizedBox(height: 4),
                  const Bone.text(words: 2),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    if (!showCardChrome) return row;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: row,
    );
  }

  // ---------------------------------------------------------------------
  // CUSTOM — caller owns the per-item layout entirely.
  // ---------------------------------------------------------------------
  Widget _buildCustom(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (i) => Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: itemBuilder!(context, i),
        ),
      ),
    );
  }
}
