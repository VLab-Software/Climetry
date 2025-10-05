import 'package:flutter/material.dart';
import '../services/location_autocomplete_service.dart';

/// Widget reutilizável de autocomplete para busca de localização
class LocationAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Function(LocationSuggestion)? onLocationSelected;
  final bool enabled;
  final Color? backgroundColor;
  final Color? textColor;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;

  const LocationAutocompleteField({
    super.key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.prefixIcon = Icons.location_on_outlined,
    this.suffixIcon,
    this.onLocationSelected,
    this.enabled = true,
    this.backgroundColor,
    this.textColor,
    this.validator,
    this.focusNode,
  });

  @override
  State<LocationAutocompleteField> createState() =>
      _LocationAutocompleteFieldState();
}

class _LocationAutocompleteFieldState extends State<LocationAutocompleteField> {
  final LocationAutocompleteService _autocompleteService =
      LocationAutocompleteService();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<LocationSuggestion> _suggestions = [];
  bool _isSearching = false;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _autocompleteService.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged(String query) async {
    if (query.trim().length < 3) {
      _removeOverlay();
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final results = await _autocompleteService.searchWithDebounce(
        query,
        const Duration(milliseconds: 500),
      );

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isSearching = false;
        });

        if (_suggestions.isNotEmpty && _focusNode.hasFocus) {
          _showOverlay();
        } else {
          _removeOverlay();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isSearching = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: _getFieldWidth(),
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, _getFieldHeight()),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            color: widget.backgroundColor ?? const Color(0xFF2A3A4D),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _suggestions[index];
                  return InkWell(
                    onTap: () => _selectSuggestion(suggestion),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: const Color(0xFF4A9EFF),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              suggestion.displayName,
                              style: TextStyle(
                                color: widget.textColor ?? Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _selectSuggestion(LocationSuggestion suggestion) {
    widget.controller.text = suggestion.displayName;
    _removeOverlay();
    setState(() {
      _suggestions = [];
    });
    _focusNode.unfocus();

    if (widget.onLocationSelected != null) {
      widget.onLocationSelected!(suggestion);
    }
  }

  double _getFieldWidth() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.width ?? 300;
  }

  double _getFieldHeight() {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    return renderBox?.size.height ?? 56;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        validator: widget.validator,
        style: TextStyle(color: widget.textColor ?? Colors.white),
        onChanged: _onTextChanged,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: (widget.textColor ?? Colors.white).withOpacity(0.3),
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(widget.prefixIcon, color: Colors.white60)
              : null,
          suffixIcon: _isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4A9EFF),
                      ),
                    ),
                  ),
                )
              : widget.suffixIcon,
          filled: true,
          fillColor: widget.backgroundColor ?? const Color(0xFF2A3A4D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
