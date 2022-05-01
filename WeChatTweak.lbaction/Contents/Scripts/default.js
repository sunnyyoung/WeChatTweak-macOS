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

  var arr=[];
  var jsonArr=result.data.items;
   jsonArr.forEach(function (i) {
    arr.push( {
      title: i.title,
      subtitle: i.subtitle,
      icon: i.icon.path,
      action: "open",
      actionArgument: i.arg
    })
  });
 

  // return JSON.stringify(result.data);
  return arr;

}

function open(id) {
  LaunchBar.hide()
  HTTP.get('http://localhost:48065/wechat/start?session=' + id);
}
