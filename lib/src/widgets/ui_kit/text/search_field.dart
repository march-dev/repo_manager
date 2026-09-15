import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
      child: TextField(
        controller: _controller,
        // setState just to redraw the suffix clear button's visibility —
        // the actual filtering runs through widget.onChanged into the
        // caller's own state.
        onChanged: (value) => setState(() => widget.onChanged(value)),
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          isDense: true,
          // Matching the app background (rather than the theme's default
          // fill) lets this sit flush with the page instead of reading as a
          // separate floating panel.
          filled: true,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          hintText: widget.hintText,
          hintStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
          prefixIcon: const Icon(CupertinoIcons.search, size: 16),
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
                  icon:
                      const Icon(CupertinoIcons.clear_circled_solid, size: 16),
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
          // Explicit enabled/focused borders — otherwise focusing this field
          // pulls in the theme's default focused-border color (typically a
          // bright accent), which can read far louder than whatever sits
          // next to it. Focused is a lightened step of the same outline
          // (not a different hue), so it reads as "this field is active"
          // without shouting.
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Color.lerp(
                Theme.of(context).colorScheme.outline,
                Theme.of(context).colorScheme.onSurface,
                0.4,
              )!,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 11.5),
        ),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
