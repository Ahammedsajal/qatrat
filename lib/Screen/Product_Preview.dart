import 'dart:io';
import 'package:customer/Helper/Color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/vimeoplayer.dart';

class ProductPreview extends StatefulWidget {
  final int? pos;
  final int? secPos;
  final int? index;
  final bool? list;
  final bool? from;
  final String? id;
  final String? video;
  final String? videoType;
  final List<String?>? imgList;
  const ProductPreview(
      {super.key,
      this.pos,
      this.secPos,
      this.index,
      this.list,
      this.id,
      this.imgList,
      this.video,
      this.videoType,
      this.from,});
  @override
  State<StatefulWidget> createState() => StatePreview();
}

class StatePreview extends State<ProductPreview> {
  int? curPos;
  YoutubePlayerController? _controller;
  VideoPlayerController? _videoController;
  @override
  void initState() {
    super.initState();
    if (widget.from! && widget.videoType == "youtube") {
      _controller = YoutubePlayerController(
        initialVideoId: YoutubePlayer.convertUrlToId(widget.video!)!,
        flags: const YoutubePlayerFlags(
            disableDragSeek: true,),
      );
    } else if (widget.from! &&
        widget.videoType == "self_hosted" &&
        widget.video != "") {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.video!),
              videoPlayerOptions: VideoPlayerOptions(
                mixWithOthers: true,
              ),);
      _videoController!.addListener(() {
        setState(() {});
      });
      _videoController!.setLooping(false);
      _videoController!.initialize();
    }
    curPos = widget.pos;
  }

  @override
  void dispose() {
    super.dispose();
    _setPortraitOrientation();
    if (_controller != null) _controller!.dispose();
    if (_videoController != null) _videoController!.dispose();
  }

  @override
  void deactivate() {
    if (_controller != null) _controller!.pause();
    super.deactivate();
  }

  void _setPortraitOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: Platform.isAndroid ? false : true,
      child: Scaffold(
          body: Stack(
        children: <Widget>[
          if (widget.video == "") Container(
                  child: PhotoViewGallery.builder(
                  scrollPhysics: const BouncingScrollPhysics(),
                  builder: (BuildContext context, int index) {
                    return PhotoViewGalleryPageOptions(
                        initialScale: PhotoViewComputedScale.contained * 0.9,
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        imageProvider: NetworkImage(widget.imgList![index]!),);
                  },
                  itemCount: widget.imgList!.length,
                  loadingBuilder: (context, event) => Center(
                    child: SizedBox(
                      width: 20.0,
                      height: 20.0,
                      child: CircularProgressIndicator(
                        value: event == null
                            ? 0
                            : event.cumulativeBytesLoaded /
                                event.expectedTotalBytes!,
                      ),
                    ),
                  ),
                  backgroundDecoration:
                      BoxDecoration(color: Theme.of(context).colorScheme.white),
                  pageController: PageController(initialPage: curPos!),
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() {
                        curPos = index;
                      });
                    }
                  },
                ),) else PageView.builder(
                  itemCount: widget.imgList!.length,
                  controller: PageController(initialPage: curPos!),
                  onPageChanged: (index) {
                    if (mounted) {
                      setState(() {
                        curPos = index;
                      });
                    }
                    if (index != 1 ||
                        !(widget.from! &&
                            widget.videoType != null &&
                            widget.video != "")) {
                      _setPortraitOrientation();
                    }
                  },
                  itemBuilder: (BuildContext context, int index) {
                    if (index == 1 &&
                        widget.from! &&
                        widget.videoType != null &&
                        widget.video != "") {
                      if (widget.videoType == "youtube") {
                        _controller!.reset();
                        return SafeArea(
                          child: YoutubePlayer(
                            controller: _controller!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor:
                                Theme.of(context).colorScheme.fontColor,
                            liveUIColor:
                                Theme.of(context).colorScheme.primarytheme,
                          ),
                        );
                      } else if (widget.videoType == "vimeo") {
                        final List<String> id =
                            widget.video!.split("https://vimeo.com/");
                        return SafeArea(
                            child: SizedBox(
                          width: double.maxFinite,
                          height: double.maxFinite,
                          child: Center(
                            child: VimeoPlayer(
                              id: id[1],
                              autoPlay: true,
                              looping: false,
                            ),
                          ),
                        ),);
                      } else {
                        return _videoController!.value.isInitialized
                            ? AspectRatio(
                                aspectRatio:
                                    _videoController!.value.aspectRatio,
                                child: Stack(
                                  alignment: Alignment.bottomCenter,
                                  children: <Widget>[
                                    VideoPlayer(
                                      _videoController!,
                                    ),
                                    _ControlsOverlay(
                                        controller: _videoController,),
                                    VideoProgressIndicator(_videoController!,
                                        allowScrubbing: true,),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink();
                      }
                    }
                    return PhotoView(
                        backgroundDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.white,),
                        initialScale: PhotoViewComputedScale.contained * 0.9,
                        minScale: PhotoViewComputedScale.contained * 0.9,
                        customSize: MediaQuery.of(context).size,
                        imageProvider: NetworkImage(widget.imgList![index]!),);
                  },),
          Positioned(
            top: 34.0,
            left: 5.0,
            child: Material(
                color: Colors.transparent,
                child: Container(
                  margin: const EdgeInsets.all(10),
                  decoration: shadow(),
                  child: Card(
                    elevation: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        _setPortraitOrientation();
                        Navigator.of(context).pop();
                      },
                      child: Center(
                        child: Icon(
                          Icons.keyboard_arrow_left,
                          color: Theme.of(context).colorScheme.primarytheme,
                        ),
                      ),
                    ),
                  ),
                ),),
          ),
          Positioned(
              bottom: 10.0,
              left: 25.0,
              right: 25.0,
              child: SelectedPhoto(
                numberOfDots: widget.imgList!.length,
                photoIndex: curPos,
              ),),
        ],
      ),),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({this.controller});
  static const _examplePlaybackRates = [
    0.25,
    0.5,
    1.0,
    1.5,
    2.0,
    3.0,
    5.0,
    10.0,
  ];
  final VideoPlayerController? controller;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 50),
          reverseDuration: const Duration(milliseconds: 200),
          child: controller!.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 100.0,
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: () {
            controller!.value.isPlaying
                ? controller!.pause()
                : controller!.play();
          },
        ),
        Align(
          alignment: Alignment.topRight,
          child: PopupMenuButton<double>(
            initialValue: controller!.value.playbackSpeed,
            tooltip: 'Playback speed',
            onSelected: (speed) {
              controller!.setPlaybackSpeed(speed);
            },
            itemBuilder: (context) {
              return [
                for (final speed in _examplePlaybackRates)
                  PopupMenuItem(
                    value: speed,
                    child: Text('${speed}x'),
                  ),
              ];
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 16,
              ),
              child: Text('${controller!.value.playbackSpeed}x'),
            ),
          ),
        ),
      ],
    );
  }
}

class SelectedPhoto extends StatelessWidget {
  final int? numberOfDots;
  final int? photoIndex;
  const SelectedPhoto({super.key, this.numberOfDots, this.photoIndex});
  Widget _inactivePhoto(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 3.0, end: 3.0),
        child: Container(
          height: 8.0,
          width: 8.0,
          decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primarytheme.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4.0),),
        ),
      ),
    );
  }

  Widget _activePhoto(BuildContext context) {
    return Container(
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 5.0, end: 5.0),
        child: Container(
          height: 10.0,
          width: 10.0,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primarytheme,
              borderRadius: BorderRadius.circular(5.0),
              boxShadow: const [
                BoxShadow(
                    color: Colors.grey, blurRadius: 2.0,),
              ],),
        ),
      ),
    );
  }

  List<Widget> _buildDots(BuildContext context) {
    final List<Widget> dots = [];
    for (int i = 0; i < numberOfDots!; i++) {
      dots.add(
          i == photoIndex ? _activePhoto(context) : _inactivePhoto(context),);
    }
    return dots;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _buildDots(context),
      ),
    );
  }
}
