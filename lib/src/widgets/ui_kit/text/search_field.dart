import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../theme/app_sizes.dart';
import 'app_text_field.dart';

/// A quick filter box: a fixed-width text field with a search icon and a
/// clear button that only appears once there's something to clear.
class SearchField extends StatefulWidget {
  const SearchField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.hintText,
    this.width = 220,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final String hintText;

  /// A fixed width rather than flexing with its surroundings — this is
  /// meant to be a quick filter box, not a primary layout element.
  final double width;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

const _actionIconSize = 32.0;

class _SearchFieldState extends State<SearchField> {
  // Owns its own controller rather than rebuilding from widget.value on
  // every keystroke — the caller's own value only ever changes via this
  // field's own onChanged, so there's no external source to resync from,
  // and doing so would just risk fighting the cursor position.
  late final _controller = TextEditingController(text: widget.value);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: AppTextField(
        controller: _controller,
        hintText: widget.hintText,
        // setState just to redraw the suffix clear button's visibility —
        // the actual filtering runs through widget.onChanged into the
        // caller's own state.
        onChanged: (value) => setState(() => widget.onChanged(value)),
        prefixIcon: const Icon(CupertinoIcons.search, size: AppSizes.iconSmall),
        prefixIconConstraints: const BoxConstraints(
          minWidth: _actionIconSize,
          maxHeight: _actionIconSize,
        ),
        // Both icon slots are constrained to the same fixed size, and the
        // clear IconButton's own tap-target constraints are pinned too —
        // otherwise its default (48x48) intent overflows this field's
        // fixed height the moment it appears, regrowing the field to a
        // different height depending on whether text has been typed.
        suffixIconConstraints: const BoxConstraints(
          minWidth: _actionIconSize,
          maxHeight: _actionIconSize,
        ),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(CupertinoIcons.clear_circled_solid,
                    size: AppSizes.iconSmall),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  maxWidth: _actionIconSize,
                  maxHeight: _actionIconSize,
                ),
                onPressed: () {
                  _controller.clear();
                  widget.onChanged('');
                  setState(() {});
                },
              ),
        // 1px off each side from before — shaves the field's overall
        // height from 34 to 32, aligning it with this row's other
        // controls (e.g. the grouping toggle/refresh button).
        contentPadding: const EdgeInsets.symmetric(vertical: 10.5),
      ),
    );
  }
}
