function getValue(obj)
{
    return obj.value;
}

function ExistValue(obj,value)
{
    for(var i = 0; i<obj.options.length; i++)
    {
        if(obj.options[i].value == value)
            {
                return true;
            }
    }
    return false;
}

function AddItem(obj, text, value)
{
    if(!ExistValue(obj,value))
    {
        var varItem = new Option(text,value);
        obj.options.add(varItem);
    }
}

function RemoveItems(obj,value)
{
    for(var i=0;i<obj.options.length;i++)
        {
            if(obj.options[i].value == value)
                obj.remove(i);
        }
}

function HideContent(obj)
{
    obj.style.display = "none";
}

function ShowContent(obj)
{
    obj.style.display = "";
}

function checkChartStyle(obj)
{
    var obj_l_project = document.getElementById('l_project')
    var obj_s_project=document.getElementById('s_project');
    var obj_l_status=document.getElementById('l_status');
    var obj_s_status=document.getElementById('s_status');

    var obj_l_tracker=document.getElementById('l_tracker');
    var obj_s_tracker=document.getElementById('s_tracker');

    var obj_l_assigned_to = document.getElementById('l_assigned_to');
    var obj_s_assigned_to = document.getElementById('s_assigned_to');

    var obj_l_version = document.getElementById('l_version');
    var obj_s_version = document.getElementById('s_version')
    
    if(getValue(obj) == 1)
    {
        RemoveItems(obj_s_project,"all");
        AddItem(obj_s_tracker,"所有状态","all");
        ShowContent(obj_l_project);
        ShowContent(obj_s_project);
        ShowContent(obj_l_status);
        ShowContent(obj_s_status);
        ShowContent(obj_l_tracker);
        ShowContent(obj_s_tracker);
        ShowContent(obj_l_assigned_to);
        ShowContent(obj_s_assigned_to);
        ShowContent(obj_l_version);
        ShowContent(obj_s_version);
    }
    else if(getValue(obj) == 2)
    {
        ShowContent(obj_l_project);
        ShowContent(obj_s_project);
        ShowContent(obj_l_assigned_to);
        ShowContent(obj_s_assigned_to);
        HideContent(obj_l_status);
        HideContent(obj_s_status);
        HideContent(obj_l_tracker);
        HideContent(obj_s_tracker);
    }
    else if(getValue(obj) == 3)
    {
        RemoveItems(obj_s_tracker, "all");
        HideContent(obj_l_assigned_to);
        HideContent(obj_s_assigned_to);
        HideContent(obj_l_status);
        HideContent(obj_s_status);
        ShowContent(obj_l_project);
        ShowContent(obj_s_project);
        ShowContent(obj_l_tracker);
        ShowContent(obj_s_tracker);
        ShowContent(obj_l_version);
        ShowContent(obj_s_version);
    }
    else if(getValue(obj) == 4)
    {
        HideContent(obj_l_project);
        HideContent(obj_s_project);
        HideContent(obj_l_status);
        HideContent(obj_s_status);
        HideContent(obj_l_tracker);
        HideContent(obj_s_tracker);
        HideContent(obj_l_assigned_to);
        HideContent(obj_s_assigned_to);
        HideContent(obj_l_version);
        HideContent(obj_s_version);
    }
}

function checkTrendChart(obj)
{
    var obj_l_priority = document.getElementById("l_priority");
    var obj_s_priority = document.getElementById("s_priority");
    var obj_s_tracker = document.getElementById("s_tracker");

    if(getValue(obj)==1)
    {
        AddItem(obj_s_tracker,"所有类型","all");
        ShowContent(obj_l_priority);
        ShowContent(obj_s_priority);
    }
    else
    {
        RemoveItems(obj_s_tracker,"all");
        HideContent(obj_l_priority);
        HideContent(obj_s_priority);
    }
}

function checkPersonalChart(obj)
{
    var obj_l_priority = document.getElementById("l_priority");
    var obj_s_priority = document.getElementById("s_priority");

    if(getValue(obj)==1)
    {
        HideContent(obj_l_priority);
        HideContent(obj_s_priority);
    }
    else if(getValue(obj) == 2)
    {
        ShowContent(obj_l_priority);
        ShowContent(obj_s_priority);
    }
    else if(getValue(obj) == 3)
    {
        HideContent(obj_l_priority);
        HideContent(obj_s_priority);
    }
}

function checkVersion(obj)
{
    var obj_l_version = document.getElementById("l_version");
    var obj_s_version = document.getElementById("s_version");

    if(getValue(obj) == 'all')
    {
        HideContent(obj_l_version);
        HideContent(obj_s_version);
    }
    else
    {
        ShowContent(obj_l_version);
        ShowContent(obj_s_version);
    }
}
function checkTeamChart(obj)
{
    var obj_l_observe = document.getElementById("l_observe");
    var obj_s_observe = document.getElementById("s_observe");
    var obj_l_team = document.getElementById("l_team");
    var obj_s_team = document.getElementById("s_team");
    var obj_s_project = document.getElementById("s_project");

    if(getValue(obj) == 1)
    {
        RemoveItems(obj_s_project, "all")
        HideContent(obj_l_observe);
        HideContent(obj_s_observe);
        HideContent(obj_l_team);
        HideContent(obj_s_team);
    }
    else if(getValue(obj) == 2)
    {
        RemoveItems(obj_s_project, "all")
        HideContent(obj_l_observe);
        HideContent(obj_s_observe);
        HideContent(obj_l_team);
        HideContent(obj_s_team);
    }
    else if(getValue(obj) == 3)
    {
        RemoveItems(obj_s_project, "all")
        AddItem(obj_s_observe, "investigated issues", '1');
        AddItem(obj_s_observe, "resolved issues", '2');
        AddItem(obj_s_observe, "av_inves time", '3');
        AddItem(obj_s_observe, "reopened issues", '4');
        AddItem(obj_s_observe, "regression issues", '5');
        RemoveItems(obj_s_observe, '6');
        RemoveItems(obj_s_observe, '7');
        RemoveItems(obj_s_observe, '8');
        RemoveItems(obj_s_observe, '9');
        ShowContent(obj_l_observe);
        ShowContent(obj_s_observe);
        HideContent(obj_l_team);
        HideContent(obj_s_team);
    }
    else if(getValue(obj) == 4)
    {
        RemoveItems(obj_s_project, "all")
        RemoveItems(obj_s_observe, '1');
        RemoveItems(obj_s_observe, '2');
        RemoveItems(obj_s_observe, '3');
        RemoveItems(obj_s_observe, '4');
        RemoveItems(obj_s_observe, '5');
        AddItem(obj_s_observe, "found issues", '6')
        AddItem(obj_s_observe, "notabug issues", '7');
        AddItem(obj_s_observe, "fixreopen issues", '8');
        AddItem(obj_s_observe, "fixed issues", '9');
        ShowContent(obj_l_observe);
        ShowContent(obj_s_observe);
        HideContent(obj_l_team);
        HideContent(obj_s_team);
    }
    else if(getValue(obj) == 5)
    {
        AddItem(obj_s_project, "所有项目", 'all')
        ShowContent(obj_l_team);
        ShowContent(obj_s_team);
        HideContent(obj_l_observe);
        HideContent(obj_s_observe);
    }
    else if(getValue(obj) == 6)
    {
        AddItem(obj_s_project, "所有项目", 'all')
        ShowContent(obj_l_team);
        ShowContent(obj_s_team);
        HideContent(obj_l_observe);
        HideContent(obj_s_observe);
    }
}

function getNextSibling(startBrother)
{
  endBrother=startBrother.nextSibling;
  while(endBrother.nodeType!=1){
    endBrother = endBrother.nextSibling;
  }
  return endBrother;
}

function show_details(obj)
{

    var n_span = getNextSibling(obj);
    var nn_span = getNextSibling(n_span);

    if(obj.alt=='显示组员详情')
    {
        obj.src = "/images/less_details.png";
        obj.alt = "隐藏组员详情";
        n_span.style.display = "";
        nn_span.style.display = "none";
    }
    else
    {
        obj.alt = "显示组员详情";
        obj.src = "/images/more_details.png";
        n_span.style.display = "none";
        nn_span.style.display = "";
    }

   var g_details = getNextSibling(obj.parentNode.parentNode.parentNode);
   if(g_details.style.display == 'none')
   {
      g_details.style.display = "";
   }
   else
      g_details.style.display = 'none';


}