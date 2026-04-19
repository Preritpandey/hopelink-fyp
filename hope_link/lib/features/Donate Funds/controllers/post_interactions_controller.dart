import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../models/post_interaction_models.dart';
import '../services/post_interaction_service.dart';

class PostInteractionsController extends GetxController {
  PostInteractionsController({
    required this.postId,
    required PostInteractionState initialState,
    this.onInteractionChanged,
  }) : interaction = initialState.obs;

  final String postId;
  final void Function(PostInteractionState state)? onInteractionChanged;
  final PostInteractionService _service = PostInteractionService();

  final TextEditingController commentController = TextEditingController();
  final Rx<PostInteractionState> interaction;
  final RxList<PostComment> comments = <PostComment>[].obs;
  final RxBool isLoadingComments = false.obs;
  final RxBool isSubmittingComment = false.obs;
  final RxBool isTogglingLike = false.obs;
  final RxString commentsError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadComments();
  }

  void _emitInteraction(PostInteractionState state) {
    interaction.value = state;
    onInteractionChanged?.call(state);
  }

  Future<void> loadComments() async {
    try {
      isLoadingComments.value = true;
      commentsError.value = '';
      final loadedComments = await _service.fetchComments(postId);
      comments.assignAll(loadedComments);
      _emitInteraction(
        interaction.value.copyWith(commentsCount: loadedComments.length),
      );
    } catch (error) {
      commentsError.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoadingComments.value = false;
    }
  }

  Future<void> toggleLike() async {
    try {
      isTogglingLike.value = true;
      final nextState = interaction.value.isLikedByCurrentUser
          ? await _service.unlikePost(postId)
          : await _service.likePost(postId);
      _emitInteraction(
        interaction.value.copyWith(
          totalLikes: nextState.totalLikes,
          isLikedByCurrentUser: nextState.isLikedByCurrentUser,
        ),
      );
      HapticFeedback.lightImpact();
    } catch (error) {
      Get.snackbar(
        'Action unavailable',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } finally {
      isTogglingLike.value = false;
    }
  }

  Future<void> submitComment() async {
    final text = commentController.text.trim();
    if (text.isEmpty) return;

    try {
      isSubmittingComment.value = true;
      final comment = await _service.addComment(postId, text);
      comments.insert(0, comment);
      commentController.clear();
      _emitInteraction(
        interaction.value.copyWith(commentsCount: comments.length),
      );
      HapticFeedback.lightImpact();
    } catch (error) {
      Get.snackbar(
        'Comment failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } finally {
      isSubmittingComment.value = false;
    }
  }

  Future<void> deleteOwnComment(PostComment comment) async {
    try {
      await _service.deleteComment(comment.id);
      comments.removeWhere((item) => item.id == comment.id);
      _emitInteraction(
        interaction.value.copyWith(commentsCount: comments.length),
      );
      Get.snackbar(
        'Comment removed',
        'Your comment was deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColorToken.primary.color.withOpacity(0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    } catch (error) {
      Get.snackbar(
        'Delete failed',
        error.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withOpacity(0.92),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 14,
      );
    }
  }

  @override
  void onClose() {
    commentController.dispose();
    super.onClose();
  }
}
