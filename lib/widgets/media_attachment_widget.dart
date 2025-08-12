import 'package:flutter/material.dart';

import '../models/media_attachment.dart';

/// Widget for displaying and managing media attachments
class MediaAttachmentWidget extends StatelessWidget {
  final MediaAttachment attachment;
  final VoidCallback? onRemove;
  final ValueChanged<String?>? onDescriptionChanged;
  final bool showDescription;
  final bool isEditable;

  const MediaAttachmentWidget({
    super.key,
    required this.attachment,
    this.onRemove,
    this.onDescriptionChanged,
    this.showDescription = true,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Media preview
          _buildMediaPreview(context),
          
          // Media info and controls
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // File info
                Row(
                  children: [
                    Icon(
                      attachment.isImage ? Icons.image : Icons.videocam,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        attachment.fileName,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      attachment.formattedSize,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                
                // Description field
                if (showDescription && isEditable) ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Alt text (optional)',
                      hintText: 'Describe this image for accessibility',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 2,
                    maxLength: 200,
                    onChanged: onDescriptionChanged,
                    controller: TextEditingController(
                      text: attachment.description ?? '',
                    ),
                  ),
                ] else if (showDescription && attachment.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Alt text: ${attachment.description}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                
                // Remove button
                if (isEditable && onRemove != null) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Remove'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context) {
    if (attachment.isImage) {
      return _buildImagePreview(context);
    } else if (attachment.isVideo) {
      return _buildVideoPreview(context);
    } else {
      return _buildGenericPreview(context);
    }
  }

  Widget _buildImagePreview(BuildContext context) {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          // Image
          if (attachment.file != null)
            Image.file(
              attachment.file!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPreview(context, 'Failed to load image');
              },
            )
          else if (attachment.bytes != null)
            Image.memory(
              attachment.bytes!,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPreview(context, 'Failed to load image');
              },
            )
          else
            _buildErrorPreview(context, 'No image data'),
          
          // Remove button overlay
          if (isEditable && onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(BuildContext context) {
    return Container(
      height: 200,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Stack(
        children: [
          // Video placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Text(
                  'Video Preview',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  attachment.fileName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Remove button overlay
          if (isEditable && onRemove != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.close, color: Colors.white),
                  iconSize: 20,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenericPreview(BuildContext context) {
    return Container(
      height: 120,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.attachment,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'Unsupported Media',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPreview(BuildContext context, String message) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Theme.of(context).colorScheme.errorContainer,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for displaying a grid of media attachments
class MediaAttachmentGrid extends StatelessWidget {
  final List<MediaAttachment> attachments;
  final ValueChanged<MediaAttachment>? onRemove;
  final ValueChanged<MediaAttachment>? onDescriptionChanged;
  final bool isEditable;

  const MediaAttachmentGrid({
    super.key,
    required this.attachments,
    this.onRemove,
    this.onDescriptionChanged,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(
                Icons.attachment,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '${attachments.length} attachment${attachments.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Attachments
        ...attachments.map((attachment) => Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: MediaAttachmentWidget(
            attachment: attachment,
            onRemove: isEditable && onRemove != null 
                ? () => onRemove!(attachment)
                : null,
            onDescriptionChanged: isEditable && onDescriptionChanged != null
                ? (description) {
                    final updatedAttachment = attachment.copyWith(
                      description: description?.isEmpty == true ? null : description,
                    );
                    onDescriptionChanged!(updatedAttachment);
                  }
                : null,
            isEditable: isEditable,
          ),
        )),
      ],
    );
  }
}