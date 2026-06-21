using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using ReactiveUI;
using ReactiveUI.Fody.Helpers;
using SS14.Launcher.Api;
using SS14.Launcher.Localization;
using SS14.Launcher.Models.Data;
using SS14.Launcher.Models.Logins;

namespace SS14.Launcher.ViewModels.Login;

public class LoginViewModel : BaseLoginViewModel
{
    private readonly AuthApi _authApi;
    private readonly LoginManager _loginMgr;
    private readonly DataManager _dataManager;
    private readonly LocalizationManager _loc = LocalizationManager.Instance;

    [Reactive] public string EditingUsername { get; set; } = "";
    [Reactive] public string EditingPassword { get; set; } = "";
    [Reactive] public string EditingSsoCode { get; set; } = "";

    [Reactive] public bool IsInputValid { get; private set; }
    [Reactive] public bool IsPasswordVisible { get; set; }
    [Reactive] public bool ShowLegacyLogin { get; set; }
    [Reactive] public bool ShowSsoCodeInput { get; set; }
    [Reactive] public bool HasYandex { get; set; }
    [Reactive] public bool HasVk { get; set; }
    [Reactive] public bool HasLegacy { get; set; }

    public LoginViewModel(MainWindowLoginViewModel parentVm, AuthApi authApi,
        LoginManager loginMgr, DataManager dataManager) : base(parentVm)
    {
        BusyText = _loc.GetString("login-login-busy-logging-in");
        _authApi = authApi;
        _loginMgr = loginMgr;
        _dataManager = dataManager;

        this.WhenAnyValue(x => x.EditingUsername, x => x.EditingPassword)
            .Subscribe(s => { IsInputValid = !string.IsNullOrEmpty(s.Item1) && !string.IsNullOrEmpty(s.Item2); });

        _ = LoadAuthMethods();
    }

    private async Task LoadAuthMethods()
    {
        var methods = await _authApi.GetAuthMethodsAsync();
        if (methods == null)
            methods = new[] { "legacy", "yandex", "vkontakte" };

        HasYandex = methods.Contains("yandex");
        HasVk = methods.Contains("vkontakte");
        HasLegacy = methods.Contains("legacy");
    }

    public void SsoLogin(string provider)
    {
        var url = $"{ConfigConstants.AccountBaseUrl}../../LauncherSSO";
        Helpers.OpenUri(url);
        ShowSsoCodeInput = true;
    }

    public async void OnSsoCodeSubmit()
    {
        var code = EditingSsoCode?.Trim();
        if (string.IsNullOrEmpty(code) || Busy)
            return;

        Busy = true;
        BusyText = _loc.GetString("login-login-busy-logging-in");
        try
        {
            var resp = await _authApi.SsoLoginAsync(code);

            var request = new AuthApi.AuthenticateRequest(code, code);
            await DoLogin(this, request, resp, _loginMgr, _authApi);

            _dataManager.CommitConfig();
        }
        finally
        {
            Busy = false;
            BusyText = _loc.GetString("login-login-busy-logging-in");
        }
    }

    public void ToggleLegacyLogin()
    {
        ShowLegacyLogin = !ShowLegacyLogin;
    }

    public async void OnLogInButtonPressed()
    {
        if (!IsInputValid || Busy)
        {
            return;
        }

        Busy = true;
        try
        {
            var request = new AuthApi.AuthenticateRequest(EditingUsername, EditingPassword);
            var resp = await _authApi.AuthenticateAsync(request);

            await DoLogin(this, request, resp, _loginMgr, _authApi);

            _dataManager.CommitConfig();
        }
        finally
        {
            Busy = false;
        }
    }

    public static async Task<bool> DoLogin<T>(
        T vm,
        AuthApi.AuthenticateRequest request,
        AuthenticateResult resp,
        LoginManager loginMgr,
        AuthApi authApi)
        where T : BaseLoginViewModel, IErrorOverlayOwner
    {
        var loc = LocalizationManager.Instance;
        if (resp.IsSuccess)
        {
            var loginInfo = resp.LoginInfo;
            var oldLogin = loginMgr.Logins.Lookup(loginInfo.UserId);
            if (oldLogin.HasValue)
            {
                await authApi.LogoutTokenAsync(oldLogin.Value.LoginInfo.Token.Token);
                loginMgr.ActiveAccountId = loginInfo.UserId;
                loginMgr.UpdateToNewToken(loginMgr.ActiveAccount!, loginInfo.Token);
                return true;
            }

            loginMgr.AddFreshLogin(loginInfo);
            loginMgr.ActiveAccountId = loginInfo.UserId;
            return true;
        }

        if (resp.Code == AuthApi.AuthenticateDenyResponseCode.TfaRequired)
        {
            vm.ParentVM.SwitchToAuthTfa(request);
            return false;
        }

        var errors = AuthErrorsOverlayViewModel.AuthCodeToErrors(resp.Errors, resp.Code);
        vm.OverlayControl = new AuthErrorsOverlayViewModel(vm, loc.GetString("login-login-error-title"), errors);
        return false;
    }

    public void RegisterPressed()
    {
        Helpers.OpenUri(ConfigConstants.AccountRegisterUrl);
    }

    public void ResendConfirmationPressed()
    {
        Helpers.OpenUri(ConfigConstants.AccountResendConfirmationUrl);
    }
}
