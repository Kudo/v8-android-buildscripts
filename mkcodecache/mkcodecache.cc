// Copyright 2006-2008 the V8 project authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "include/libplatform/libplatform.h"
#include "include/v8-initialization.h"
#include "include/v8-message.h"
#include "include/v8-script.h"
#include "src/base/platform/platform.h"
#include "src/base/platform/wrappers.h"

#include <chrono>

namespace v8 {

namespace {

// Reads a file into a v8 string.
Local<String> ReadFile(Isolate* isolate, const char* name,
                              bool should_throw) {
  std::unique_ptr<base::OS::MemoryMappedFile> file(
      base::OS::MemoryMappedFile::open(
          name, base::OS::MemoryMappedFile::FileMode::kReadOnly));
  if (!file) {
    if (should_throw) {
      std::ostringstream oss;
      oss << "Error loading file: \"" << name << '"';
      isolate->ThrowError(
          v8::String::NewFromUtf8(isolate, oss.str().c_str()).ToLocalChecked());
    }
    return Local<String>();
  }

  int size = static_cast<int>(file->size());
  char* chars = static_cast<char*>(file->memory());
  Local<String> result = String::NewFromUtf8(isolate, chars, NewStringType::kNormal, size)
                 .ToLocalChecked();
  return result;
}

} // namespace

} // namespace v8

int main(int argc, char** argv) {
  if (argc < 2) {
    ::printf("Usage: %s script_file\n", argv[0]);
    exit(1);
  }

  v8::base::EnsureConsoleOutput();
  v8::V8::InitializeICUDefaultLocation(argv[0]);
  std::unique_ptr<v8::Platform> platform = v8::platform::NewDefaultPlatform();
  v8::V8::InitializePlatform(platform.get());
  v8::V8::SetFlagsFromString("--nolazy");
  v8::V8::Initialize();
  v8::V8::InitializeExternalStartupData(argv[0]);

  v8::Isolate::CreateParams createParams;
  auto arrayBufferAllocator =
      std::unique_ptr<v8::ArrayBuffer::Allocator>(v8::ArrayBuffer::Allocator::NewDefaultAllocator());
  createParams.array_buffer_allocator = arrayBufferAllocator.get();
  v8::Isolate* isolate = v8::Isolate::New(createParams);
  v8::HandleScope handle_scope(isolate);


  v8::Local<v8::String> source = v8::ReadFile(isolate, argv[1], false);

  if (argc == 2) {
   v8::ScriptOrigin origin = v8::ScriptOrigin(isolate, v8::String::NewFromUtf8Literal(isolate, "(mkcodecache)"));

    v8::ScriptCompiler::Source scriptSource(source, origin);
    // v8::Local<v8::UnboundScript> unboundScript = v8::ScriptCompiler::CompileUnboundScript(isolate, &scriptSource, v8::ScriptCompiler::kEagerCompile).ToLocalChecked();
    v8::Local<v8::UnboundScript> unboundScript = v8::ScriptCompiler::CompileUnboundScript(isolate, &scriptSource, v8::ScriptCompiler::kNoCompileOptions).ToLocalChecked();
    v8::ScriptCompiler::CachedData *cachedData = v8::ScriptCompiler::CreateCodeCache(unboundScript);
    ::printf("cache data size %d\n", cachedData->length);

    FILE* file = v8::base::Fopen("v8codecache.bin", "wb");
    if (file) {
      fwrite(cachedData->data, 1, cachedData->length, file);
      v8::base::Fclose(file);
    }
  } else {
    v8::ScriptOrigin origin = v8::ScriptOrigin(isolate, v8::String::NewFromUtf8Literal(isolate, "(mkcodecache)"));
    std::unique_ptr<v8::ScriptCompiler::CachedData> cachedData;
    FILE* file = v8::base::Fopen("v8codecache.bin", "rb");
    if (file) {
      fseek(file, 0, SEEK_END);
      size_t size = ftell(file);
      uint8_t *buffer = new uint8_t[size];
      rewind(file);

      if (fread(buffer, 1, size, file) != size) {
        ::printf("ooxx fread error\n");
      }
      v8::base::Fclose(file);

      cachedData = std::make_unique<v8::ScriptCompiler::CachedData>(
        buffer,
        static_cast<int>(size),
        v8::ScriptCompiler::CachedData::BufferPolicy::BufferOwned);
    }

    auto begin = std::chrono::high_resolution_clock::now();

    v8::Local<v8::Context> context = v8::Context::New(isolate);
    v8::Context::Scope context_scope(context);

    v8::ScriptCompiler::CachedData *cachedDataPtr = cachedData.release();
    v8::ScriptCompiler::Source scriptSource(source, origin, cachedDataPtr);
    // v8::ScriptCompiler::Source scriptSource(source, origin, nullptr);
    v8::Local<v8::Script> compiledScript;
    if (!v8::ScriptCompiler::Compile(context, &scriptSource, v8::ScriptCompiler::kConsumeCodeCache).ToLocal(&compiledScript)) {
    // if (!v8::ScriptCompiler::Compile(context, &scriptSource, v8::ScriptCompiler::kNoCompileOptions).ToLocal(&compiledScript)) {
      ::printf("ooxx error\n");
    }

    if (cachedDataPtr->rejected) {
      ::printf("ooxx rejected\n");
    }

    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - begin);
    ::printf("ooxx compile time: %lld\n", static_cast<long long int>(duration.count()));
  }

  v8::V8::Dispose();
  v8::V8::DisposePlatform();

  return 0;
}
