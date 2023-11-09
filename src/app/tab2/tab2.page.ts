import { Component } from '@angular/core';

@Component({
  selector: 'app-tab2',
  templateUrl: 'tab2.page.html',
  styleUrls: ['tab2.page.scss']
})
export class Tab2Page {
  public HLS_URL: string = "https://23a62c6b8b63.eu-west-1.playback.live-video.net/api/video/v1/eu-west-1.596930679883.channel.byhoj1f9kNJ0.m3u8";

  public ionicRTMPandHLS: any;

  constructor() {
    this.ionicRTMPandHLS = (<any>window).cordova.plugin.ionicrtmphls;
  }

  startPlayback() {
    this.ionicRTMPandHLS.viewLiveStream(this.HLS_URL, (res: any) => {
      console.log('SUCCESS viewLiveStream', res)
    }, (err: any) => {
      console.log('ERROR viewLiveStream', err);
    });
  }

  stopPlayback() {
    this.ionicRTMPandHLS.closeLiveStream((res: any) => {
      console.log('SUCCESS closeLiveStream', res)
    }, (err: any) => {
      console.log('ERROR closeLiveStream', err);
    });
  }
}
