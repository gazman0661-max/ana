package com.terlik.levelplayads;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.unity3d.mediation.LevelPlay;
import com.unity3d.mediation.LevelPlayAdError;
import com.unity3d.mediation.LevelPlayAdInfo;
import com.unity3d.mediation.LevelPlayAdSize;
import com.unity3d.mediation.LevelPlayConfiguration;
import com.unity3d.mediation.LevelPlayInitError;
import com.unity3d.mediation.LevelPlayInitListener;
import com.unity3d.mediation.LevelPlayInitRequest;
import com.unity3d.mediation.banner.LevelPlayBannerAdView;
import com.unity3d.mediation.banner.LevelPlayBannerAdViewListener;
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAd;
import com.unity3d.mediation.interstitial.LevelPlayInterstitialAdListener;
import com.unity3d.mediation.rewarded.LevelPlayReward;
import com.unity3d.mediation.rewarded.LevelPlayRewardedAd;
import com.unity3d.mediation.rewarded.LevelPlayRewardedAdListener;

import org.godotengine.godot.Godot;
import org.godotengine.godot.plugin.GodotPlugin;
import org.godotengine.godot.plugin.SignalInfo;
import org.godotengine.godot.plugin.UsedByGodot;

import java.util.HashSet;
import java.util.Set;

/**
 * Godot 4 <-> LevelPlay koprusu: ekranin en ustunde adaptive banner, interstitial, rewarded.
 * Godot'a giden sinyaller (ads.gd): init_success, init_failed(msg), banner_loaded(height_px),
 * rewarded_ready/unavailable/earned/closed, interstitial_ready/unavailable/closed
 */
public class LevelPlayAdsPlugin extends GodotPlugin {

    private static final String TAG = "LevelPlayAds";
    private static final long RETRY_MS = 20000L;

    private final Handler handler = new Handler(Looper.getMainLooper());

    private String bannerId = "";
    private String interstitialId = "";
    private String rewardedId = "";

    private boolean initStarted = false;
    private LevelPlayRewardedAd rewardedAd;
    private LevelPlayInterstitialAd interstitialAd;
    private LevelPlayBannerAdView banner;

    public LevelPlayAdsPlugin(Godot godot) {
        super(godot);
    }

    @Override
    public String getPluginName() {
        return "LevelPlayAds";
    }

    @Override
    public Set<SignalInfo> getPluginSignals() {
        Set<SignalInfo> s = new HashSet<>();
        s.add(new SignalInfo("init_success"));
        s.add(new SignalInfo("init_failed", String.class));
        s.add(new SignalInfo("banner_loaded", Integer.class));
        s.add(new SignalInfo("rewarded_ready"));
        s.add(new SignalInfo("rewarded_unavailable"));
        s.add(new SignalInfo("rewarded_earned"));
        s.add(new SignalInfo("rewarded_closed"));
        s.add(new SignalInfo("interstitial_ready"));
        s.add(new SignalInfo("interstitial_unavailable"));
        s.add(new SignalInfo("interstitial_closed"));
        return s;
    }

    // ---------------------------------------------------------------- INIT
    @UsedByGodot
    public void initAds(String appKey, String bannerAdUnitId, String interstitialAdUnitId, String rewardedAdUnitId) {
        final Activity act = getActivity();
        if (act == null || initStarted) return;
        initStarted = true;
        bannerId = bannerAdUnitId;
        interstitialId = interstitialAdUnitId;
        rewardedId = rewardedAdUnitId;

        act.runOnUiThread(() -> {
            LevelPlayInitRequest request = new LevelPlayInitRequest.Builder(appKey).build();
            LevelPlay.init(act, request, new LevelPlayInitListener() {
                @Override
                public void onInitSuccess(LevelPlayConfiguration configuration) {
                    // Reklam nesneleri init'ten SONRA olusturulmali
                    createRewarded();
                    if (interstitialId != null && !interstitialId.isEmpty()) createInterstitial();
                    createBanner(act);
                    emitSignal("init_success");
                }

                @Override
                public void onInitFailed(LevelPlayInitError error) {
                    initStarted = false;
                    Log.w(TAG, "init failed: " + error);
                    emitSignal("init_failed", String.valueOf(error));
                }
            });
        });
    }

    // ------------------------------------------------------------ REWARDED
    private void createRewarded() {
        LevelPlayRewardedAd ad = new LevelPlayRewardedAd(rewardedId);
        ad.setListener(new LevelPlayRewardedAdListener() {
            @Override
            public void onAdLoaded(LevelPlayAdInfo adInfo) {
                emitSignal("rewarded_ready");
            }

            @Override
            public void onAdLoadFailed(LevelPlayAdError error) {
                Log.w(TAG, "rewarded load failed: " + error);
                emitSignal("rewarded_unavailable");
                handler.postDelayed(() -> { if (rewardedAd != null) rewardedAd.loadAd(); }, RETRY_MS);
            }

            @Override
            public void onAdDisplayed(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
                Log.w(TAG, "rewarded display failed: " + error);
                emitSignal("rewarded_unavailable");
                emitSignal("rewarded_closed");
                if (rewardedAd != null) rewardedAd.loadAd();
            }

            // onAdRewarded, onAdClosed'dan SONRA da gelebilir: odulu her durumda ver
            @Override
            public void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) {
                emitSignal("rewarded_earned");
            }

            @Override
            public void onAdClicked(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdClosed(LevelPlayAdInfo adInfo) {
                emitSignal("rewarded_unavailable");
                emitSignal("rewarded_closed");
                if (rewardedAd != null) rewardedAd.loadAd();
            }

            @Override
            public void onAdInfoChanged(LevelPlayAdInfo adInfo) { }
        });
        rewardedAd = ad;
        ad.loadAd();
    }

    @UsedByGodot
    public void showRewarded() {
        final Activity act = getActivity();
        if (act == null) {
            emitSignal("rewarded_closed");
            return;
        }
        act.runOnUiThread(() -> {
            if (rewardedAd != null && rewardedAd.isAdReady()) {
                rewardedAd.showAd(act);
            } else {
                emitSignal("rewarded_closed");
            }
        });
    }

    // -------------------------------------------------------- INTERSTITIAL
    private void createInterstitial() {
        LevelPlayInterstitialAd ad = new LevelPlayInterstitialAd(interstitialId);
        ad.setListener(new LevelPlayInterstitialAdListener() {
            @Override
            public void onAdLoaded(LevelPlayAdInfo adInfo) {
                emitSignal("interstitial_ready");
            }

            @Override
            public void onAdLoadFailed(LevelPlayAdError error) {
                Log.w(TAG, "interstitial load failed: " + error);
                emitSignal("interstitial_unavailable");
                handler.postDelayed(() -> { if (interstitialAd != null) interstitialAd.loadAd(); }, RETRY_MS);
            }

            @Override
            public void onAdDisplayed(LevelPlayAdInfo adInfo) { }

            // Gosterilemese bile oyun devam etsin
            @Override
            public void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {
                Log.w(TAG, "interstitial display failed: " + error);
                emitSignal("interstitial_unavailable");
                emitSignal("interstitial_closed");
                if (interstitialAd != null) interstitialAd.loadAd();
            }

            @Override
            public void onAdClicked(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdClosed(LevelPlayAdInfo adInfo) {
                emitSignal("interstitial_unavailable");
                emitSignal("interstitial_closed");
                if (interstitialAd != null) interstitialAd.loadAd();
            }

            @Override
            public void onAdInfoChanged(LevelPlayAdInfo adInfo) { }
        });
        interstitialAd = ad;
        ad.loadAd();
    }

    @UsedByGodot
    public void showInterstitial() {
        final Activity act = getActivity();
        if (act == null) {
            emitSignal("interstitial_closed");
            return;
        }
        act.runOnUiThread(() -> {
            if (interstitialAd != null && interstitialAd.isAdReady()) {
                interstitialAd.showAd(act);
            } else {
                emitSignal("interstitial_closed");
            }
        });
    }

    // -------------------------------------------------------------- BANNER
    // Ekranin en ustu, tam genislik, adaptive. Gercek yukseklik (piksel) banner_loaded ile Godot'a gider.
    private void createBanner(Activity act) {
        if (banner != null) return;

        LevelPlayAdSize adaptive = LevelPlayAdSize.createAdaptiveAdSize(act);
        final LevelPlayAdSize size = adaptive != null ? adaptive : LevelPlayAdSize.BANNER;
        LevelPlayBannerAdView.Config config = new LevelPlayBannerAdView.Config.Builder().setAdSize(size).build();
        final LevelPlayBannerAdView view = new LevelPlayBannerAdView(act, bannerId, config);
        final int fallbackPx = (int) (size.getHeight() * act.getResources().getDisplayMetrics().density);

        view.setBannerListener(new LevelPlayBannerAdViewListener() {
            @Override
            public void onAdLoaded(LevelPlayAdInfo adInfo) {
                view.post(() -> {
                    int h = view.getHeight() > 0 ? view.getHeight() : fallbackPx;
                    emitSignal("banner_loaded", h);
                });
            }

            @Override
            public void onAdLoadFailed(LevelPlayAdError error) {
                Log.w(TAG, "banner load failed: " + error);
                handler.postDelayed(() -> { if (banner != null) banner.loadAd(); }, 30000L);
            }

            @Override
            public void onAdDisplayed(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {
                Log.w(TAG, "banner display failed: " + error);
            }

            @Override
            public void onAdClicked(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdExpanded(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdCollapsed(LevelPlayAdInfo adInfo) { }

            @Override
            public void onAdLeftApplication(LevelPlayAdInfo adInfo) { }
        });

        FrameLayout.LayoutParams params = new FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
                Gravity.TOP | Gravity.CENTER_HORIZONTAL);
        act.addContentView(view, params);
        banner = view;
        view.loadAd();
    }

    @UsedByGodot
    public void setBannerVisible(boolean visible) {
        Activity act = getActivity();
        if (act == null) return;
        act.runOnUiThread(() -> {
            if (banner == null) return;
            banner.setVisibility(visible ? View.VISIBLE : View.GONE);
            if (visible) banner.resumeAutoRefresh(); else banner.pauseAutoRefresh();
        });
    }

    // ----------------------------------------------------------- YASAM DONGUSU
    @Override
    public void onMainPause() {
        if (banner != null) banner.pauseAutoRefresh();
    }

    @Override
    public void onMainResume() {
        if (banner != null) banner.resumeAutoRefresh();
    }

    @Override
    public void onMainDestroy() {
        handler.removeCallbacksAndMessages(null);
        if (banner != null) {
            banner.destroy();
            banner = null;
        }
    }
}
