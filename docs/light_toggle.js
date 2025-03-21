function lightToggle() {
    var element = document.body;
    element.classList.toggle("light-mode");
}
const url = new URL(window.location.href);
const params = url.searchParams;