// LaunchBar Action Script

function run(string) {
  if (!string) return [];

  var url = 'http://localhost:48065/wechat/search?keyword=';
  var result = HTTP.getJSON(url + encodeURIComponent(string.trim()));

  if (result == undefined) {
    LaunchBar.alert('HTTP.getJSON() returned undefined');
    return [];
  }

  if (result.error != undefined) {
    LaunchBar.log('Error in HTTP request: ' + result.error);
    return [];
  }

  return result.data.map(function (i) {
    return {
      title: i.m_nsRemark || i.m_nsNickName,
      subtitle: i.m_nsNickName,
      icon: i.wt_avatarPath || 'icon.png',
      action: "open",
      actionArgument: i.m_nsUsrName
    }
  });
}

function open(id) {
  HTTP.get('http://localhost:48065/wechat/start?session=' + id);
}