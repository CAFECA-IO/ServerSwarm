import { create, globSource, urlSource } from "kubo-rpc-client";
import fs from "fs";
import path from "path";
import { fileTypeFromBuffer } from "file-type";

const ipfs = create({ host: "localhost", port: "5001", protocol: "http" });
(async () => {
  // Info: (20240903 - Jacky) ipfs node info
    const info = ipfs.id().then(console.log)
  // Info: (20240903 - Jacky) ipfs add string
  const { cid } = await ipfs.add("123test.txt try your best");
  console.log("cid: ", cid);
  // Info: (20240903 - Jacky) ipfs add multi file
  for await (const file of ipfs.addAll(globSource('./example_file', '**/*'))) {
      console.log(file)
    }
  // Todo: (20240903 - Jacky) ipfs add single file not working
  // const source = globSource('./example_file', '_c9d185e9-af5b-48eb-81eb-c3909cd49670.jpeg');
  // console.log('source: ', source);
  // const file = await ipfs.add(source);
  // console.log('CID: ', file);
})();

async function saveFileFromCID(cid, filePath) {
  try {
    const stream = ipfs.cat(cid);

    // 收集所有的数据块
    let buffer = Buffer.alloc(0);
    for await (const chunk of stream) {
      buffer = Buffer.concat([buffer, Buffer.from(chunk)]);
    }

    // 检测文件类型
    const fileType = await fileTypeFromBuffer(buffer);

    // 确定文件扩展名
    let extension = "";
    if (fileType) {
      extension = `.${fileType.ext}`;
      console.log("Detected file type:", fileType.mime);
    } else {
      console.log("File type could not be detected.");
    }

    // 检查文件是否为文本
    const isTextFile = fileType ? fileType.mime.startsWith("text/") : true; // 默认处理为文本文件

    if (isTextFile) {
      // 处理文本文件
      const text = buffer.toString("utf-8");
      fs.writeFileSync(`${filePath}${extension}`, text);
      console.log(`Text file saved successfully to ${filePath}${extension}`);
    } else {
      // 处理二进制文件
      fs.writeFileSync(`${filePath}${extension}`, buffer);
      console.log(`Binary file saved successfully to ${filePath}${extension}`);
    }
  } catch (error) {
    console.error("Error getting file:", error);
  }
}

// Info: (20240903 - Jacky) Example save file from cid
const cid = "QmUfMreegMrMDQDwFf8FLcDRonnoaJw3qr8cY3Y9wenwMf";
const filePath = "./output-file"; // Info (20240903 - Jacky) Save file path
saveFileFromCID(cid, filePath);
