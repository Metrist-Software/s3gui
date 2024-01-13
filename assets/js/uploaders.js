let Uploaders = {}

Uploaders.S3 = function(entries, onViewError){
  entries.forEach(entry => {
    let formData = new FormData()
    let {url, fields} = entry.meta
    Object.entries(fields).forEach(([key, val]) => formData.append(key, val))
    formData.append("file", entry.file)
    let xhr = new XMLHttpRequest()
    onViewError(() => xhr.abort() )

    // Currently there's nothing that will abort the XHR upload if an entry is cancelled.
    // onViewError doesn't fire in that case (nor would I expected it to) and there
    // aren't any other callbacks on an uploader you can use on a cancel. Everything
    // on the LV side will reflect the cancelled upload and the client side upload_entry class will
    // also reflect it but the XHR POST will keep going and eventually complete. 
    // This gets around that by aborting the upload when an entry's cancel function 
    // is called and then calling the existing old original cancel. 
    // Works in the absence of a supported callback or event we can listen for.
    let oldCancel = entry.cancel.bind(entry)
    entry.cancel = () => {
      xhr.abort()
      oldCancel()
    }

    xhr.onload = () => xhr.status === 204 ? entry.progress(100) : entry.error()
    xhr.onerror = () => entry.error()
    xhr.upload.addEventListener("progress", (event) => {
      if(event.lengthComputable){
        let percent = Math.round((event.loaded / event.total) * 100)
        if(percent < 100){ entry.progress(percent) }
      }
    })

    xhr.open("POST", url, true)
    xhr.send(formData)
  })
}

export default Uploaders;
