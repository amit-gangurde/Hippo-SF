({
    afterRender: function (component, helper) {
        
        this.superAfterRender();
        var listDOM = document.getElementById('illustration');
        var path = $A.get('$Resource.NoAccess');
        var req = new XMLHttpRequest();
        req.open('GET', path);
        req.addEventListener('load', $A.getCallback(function () {
            listDOM.innerHTML = req.response;
        }));
        req.send(null);
    }
});