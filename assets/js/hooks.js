let Hooks = {};

Hooks.DropTarget = {
  mounted() {
    let dropArea = this.el
    ;['dragenter', 'dragover', 'dragleave'].forEach(eventName => {
      dropArea.addEventListener(eventName, preventDefaults, false)
    })
    
    function preventDefaults (e) {
      e.preventDefault()
      e.stopPropagation()
    }

    ;['dragenter', 'dragover'].forEach(eventName => {
      dropArea.addEventListener(eventName, highlight, false)
    })
    
    ;['dragleave', 'drop'].forEach(eventName => {
      dropArea.addEventListener(eventName, unhighlight, false)
    })
    
    function highlight(e) {
      dropArea.classList.add('border-dashed')
      dropArea.classList.add('bg-stone-100')
    }
    
    function unhighlight(e) {
      dropArea.classList.remove('border-dashed')
      dropArea.classList.remove('bg-stone-100')
    }
  },
  updated() {
  }
};

export default Hooks;
