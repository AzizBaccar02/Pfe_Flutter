import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../conf/theme_provider.dart';
import '../../../models/client_offer_model.dart';
import '../../../services/offer_service.dart';

class MyOffersScreen extends StatefulWidget {
  const MyOffersScreen({super.key});

  @override
  State<MyOffersScreen> createState() => _MyOffersScreenState();
}

class _MyOffersScreenState extends State<MyOffersScreen> {
  String selectedFilter = 'All';

  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  List<ClientOfferModel> _offers = [];

  List<ClientOfferModel> get filteredOffers {
    if (selectedFilter == 'All') return _offers;

    if (selectedFilter == 'Open') {
      return _offers.where((offer) => offer.status == OfferStatus.open).toList();
    }

    if (selectedFilter == 'Closed') {
      return _offers
          .where((offer) => offer.status == OfferStatus.closed)
          .toList();
    }

    if (selectedFilter == 'Archived') {
      return _offers
          .where((offer) => offer.status == OfferStatus.archived)
          .toList();
    }

    return _offers;
  }

  @override
  void initState() {
    super.initState();
    _loadOffers();
  }

  Future<void> _loadOffers({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final offers = await OfferService.fetchMyOffers();

      if (!mounted) return;

      setState(() {
        _offers = offers;
        _errorMessage = null;
      });
    } on OfferException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Unable to load your offers. Please try again.';
      });
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateOfferStatus({
    required ClientOfferModel offer,
    required OfferStatus status,
  }) async {
    if (_isMutating) return;

    setState(() {
      _isMutating = true;
    });

    try {
      final updatedOffer = await OfferService.updateOfferStatus(
        offerId: offer.id,
        status: status,
      );

      if (!mounted) return;

      setState(() {
        _offers = _offers.map((item) {
          if (item.id == updatedOffer.id) return updatedOffer;
          return item;
        }).toList();
      });

      _showSnackBar('Offer updated successfully');
    } on OfferException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to update offer. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  Future<void> _confirmDeleteOffer(ClientOfferModel offer) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(
          context,
          listen: false,
        ).isDarkMode;

        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF161616) : Colors.white,
          title: Text(
            'Delete offer?',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteOffer(offer);
    }
  }

  Future<void> _deleteOffer(ClientOfferModel offer) async {
    if (_isMutating) return;

    setState(() {
      _isMutating = true;
    });

    try {
      await OfferService.deleteOffer(offerId: offer.id);

      if (!mounted) return;

      setState(() {
        _offers = _offers.where((item) => item.id != offer.id).toList();
      });

      _showSnackBar('Offer deleted successfully');
    } on OfferException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('Unable to delete offer. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    final cardColor =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF3F3F3);
    final primaryTextColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.68)
        : Colors.black.withValues(alpha: 0.68);

    return Container(
      color: backgroundColor,
      child: Column(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChipButton(
                  label: 'All',
                  selected: selectedFilter == 'All',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'All'),
                ),
                _FilterChipButton(
                  label: 'Open',
                  selected: selectedFilter == 'Open',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Open'),
                ),
                _FilterChipButton(
                  label: 'Closed',
                  selected: selectedFilter == 'Closed',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Closed'),
                ),
                _FilterChipButton(
                  label: 'Archived',
                  selected: selectedFilter == 'Archived',
                  isDarkMode: isDarkMode,
                  onTap: () => setState(() => selectedFilter = 'Archived'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildContent(
              isDarkMode: isDarkMode,
              cardColor: cardColor,
              primaryTextColor: primaryTextColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent({
    required bool isDarkMode,
    required Color cardColor,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _offers.isEmpty) {
      return _StateMessage(
        title: 'Could not load offers',
        message: _errorMessage!,
        buttonText: 'Retry',
        isDarkMode: isDarkMode,
        onPressed: () => _loadOffers(),
      );
    }

    if (filteredOffers.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _loadOffers(showLoader: false),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 80, 20, 110),
          children: [
            _StateMessageBody(
              title: 'No offers found',
              message: selectedFilter == 'All'
                  ? 'Create your first offer and it will appear here.'
                  : 'No offers match this filter.',
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadOffers(showLoader: false),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        itemCount: filteredOffers.length,
        itemBuilder: (context, index) {
          final offer = filteredOffers[index];

          return _OfferListCard(
            offer: offer,
            isDarkMode: isDarkMode,
            cardColor: cardColor,
            primaryTextColor: primaryTextColor,
            secondaryTextColor: secondaryTextColor,
            isBusy: _isMutating,
            onStatusChanged: (status) {
              _updateOfferStatus(
                offer: offer,
                status: status,
              );
            },
            onDelete: () => _confirmDeleteOffer(offer),
          );
        },
      ),
    );
  }
}

class _OfferListCard extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final Color cardColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isBusy;
  final ValueChanged<OfferStatus> onStatusChanged;
  final VoidCallback onDelete;

  const _OfferListCard({
    required this.offer,
    required this.isDarkMode,
    required this.cardColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = offer.images.isNotEmpty;
    final imagePath = hasImage ? offer.images.first : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: SizedBox(
                height: 190,
                width: double.infinity,
                child: _OfferImage(
                  imagePath: imagePath!,
                  isDarkMode: isDarkMode,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        offer.title,
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _ManageOfferMenu(
                      offer: offer,
                      isDarkMode: isDarkMode,
                      isBusy: isBusy,
                      onStatusChanged: onStatusChanged,
                      onDelete: onDelete,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  offer.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (offer.category.trim().isNotEmpty)
                      _InfoPill(
                        text: offer.category,
                        isDarkMode: isDarkMode,
                      ),
                    if (offer.city.trim().isNotEmpty)
                      _InfoPill(
                        text: offer.city,
                        isDarkMode: isDarkMode,
                      ),
                    _InfoPill(
                      text: '${offer.budget.toStringAsFixed(0)} DT',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _StatusBadge(
                      status: offer.status,
                      isDarkMode: isDarkMode,
                    ),
                    const Spacer(),
                    Text(
                      '${offer.interestedAgentsCount} interested',
                      style: TextStyle(
                        color: primaryTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferImage extends StatelessWidget {
  final String imagePath;
  final bool isDarkMode;

  const _OfferImage({
    required this.imagePath,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        isDarkMode ? const Color(0xFF222222) : const Color(0xFFEAEAEA);

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _ImageFallback(
            color: placeholderColor,
            isDarkMode: isDarkMode,
          );
        },
      );
    }

    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return _ImageFallback(
            color: placeholderColor,
            isDarkMode: isDarkMode,
          );
        },
      );
    }

    return Image.file(
      File(imagePath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return _ImageFallback(
          color: placeholderColor,
          isDarkMode: isDarkMode,
        );
      },
    );
  }
}

class _ImageFallback extends StatelessWidget {
  final Color color;
  final bool isDarkMode;

  const _ImageFallback({
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: color,
      alignment: Alignment.center,
      child: Text(
        'Image unavailable',
        style: TextStyle(
          color: isDarkMode ? Colors.white54 : Colors.black45,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ManageOfferMenu extends StatelessWidget {
  final ClientOfferModel offer;
  final bool isDarkMode;
  final bool isBusy;
  final ValueChanged<OfferStatus> onStatusChanged;
  final VoidCallback onDelete;

  const _ManageOfferMenu({
    required this.offer,
    required this.isDarkMode,
    required this.isBusy,
    required this.onStatusChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? Colors.white : Colors.black;
    final textColor = isDarkMode ? Colors.black : Colors.white;

    return PopupMenuButton<_OfferMenuAction>(
      enabled: !isBusy,
      color: isDarkMode ? const Color(0xFF202020) : Colors.white,
      onSelected: (action) {
        switch (action) {
          case _OfferMenuAction.open:
            onStatusChanged(OfferStatus.open);
            break;
          case _OfferMenuAction.closed:
            onStatusChanged(OfferStatus.closed);
            break;
          case _OfferMenuAction.archived:
            onStatusChanged(OfferStatus.archived);
            break;
          case _OfferMenuAction.delete:
            onDelete();
            break;
        }
      },
      itemBuilder: (context) {
        return [
          if (offer.status != OfferStatus.open)
            const PopupMenuItem(
              value: _OfferMenuAction.open,
              child: Text('Mark as open'),
            ),
          if (offer.status != OfferStatus.closed)
            const PopupMenuItem(
              value: _OfferMenuAction.closed,
              child: Text('Mark as closed'),
            ),
          if (offer.status != OfferStatus.archived)
            const PopupMenuItem(
              value: _OfferMenuAction.archived,
              child: Text('Archive'),
            ),
          const PopupMenuDivider(),
          const PopupMenuItem(
            value: _OfferMenuAction.delete,
            child: Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ];
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          isBusy ? '...' : 'Manage',
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

enum _OfferMenuAction {
  open,
  closed,
  archived,
  delete,
}

class _FilterChipButton extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDarkMode;
  final VoidCallback onTap;

  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.isDarkMode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedBg = isDarkMode ? Colors.white : Colors.black;
    final selectedText = isDarkMode ? Colors.black : Colors.white;
    final unselectedBg =
        isDarkMode ? const Color(0xFF161616) : const Color(0xFFF0F0F0);
    final unselectedText = isDarkMode ? Colors.white : Colors.black;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: selected ? selectedBg : unselectedBg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? selectedText : unselectedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  final bool isDarkMode;

  const _InfoPill({
    required this.text,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OfferStatus status;
  final bool isDarkMode;

  const _StatusBadge({
    required this.status,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;

    switch (status) {
      case OfferStatus.open:
        color = Colors.greenAccent;
        text = 'Open';
        break;
      case OfferStatus.closed:
        color = Colors.orangeAccent;
        text = 'Closed';
        break;
      case OfferStatus.archived:
        color = Colors.blueGrey;
        text = 'Archived';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String title;
  final String message;
  final String buttonText;
  final bool isDarkMode;
  final VoidCallback onPressed;

  const _StateMessage({
    required this.title,
    required this.message,
    required this.buttonText,
    required this.isDarkMode,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StateMessageBody(
              title: title,
              message: message,
              isDarkMode: isDarkMode,
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white : Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: isDarkMode ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateMessageBody extends StatelessWidget {
  final String title;
  final String message;
  final bool isDarkMode;

  const _StateMessageBody({
    required this.title,
    required this.message,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDarkMode ? Colors.white : Colors.black;
    final messageColor =
        isDarkMode ? Colors.white.withValues(alpha: 0.62) : Colors.black54;

    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: messageColor,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}